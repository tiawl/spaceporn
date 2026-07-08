const max_u32 = 0xffffffff;

// TODO: use status() only to display error to user (maybe show a link for webgpu errors)
function status(text) {
    document.getElementById('status').textContent = text;
}

const root = {
    wasm: null,
    console_buffer: '',
    adapter_id: null,
    device_id: null,
    timestamp: null,
    error_scope: null,
    event: null,

    // Handle management for WebGPU objects
    // Zig will reference WebGPU objects by handle ID
    handles: {
        created_id: 1,
        map: new Map(),

        create: function(obj) {
            if (this.map.size === max_u32) throw new Error('Maximum handles count reached');
            while (typeof this.map.get(this.created_id) !== 'undefined') {
                // range into [1; max_u32]
                this.created_id = (this.created_id % max_u32) + 1;
            }
            this.map.set(this.created_id, obj);
            return this.created_id;
        },

        get: function(id) {
            return this.map.get(id);
        },

        release: function(id) {
            this.map.delete(id);
        },
    },

    flushConsoleBufferAndThrowError: function(err_name) {
        let err = new Error(`${this.console_buffer.trim()}`);
        this.console_buffer = '';
        if (err_name !== null) err.name = err_name;
        throw err;
    },

    fail: function(fn_name, err) {
        console.error(`${fn_name} error:`, err);
        this.wasm.exports.onFailure();
    },

    // TODO: remove this when FPS compute is removed
    last_frame_time: 0,
    frame_count: 0,
};

console.assert = function(cond, text) {
    if (cond) return;
    if (console.assert.useDebugger) debugger;
    throw new Error(text || 'Assertion failed');
};

function update(timestamp) {
    root.timestamp = timestamp;

    // TODO: remove the FPS compute
    const dt = timestamp - root.last_frame_time;
    root.last_frame_time = timestamp;
    root.frame_count++;

    // Update FPS counter every 60 frames
    if (root.frame_count % 60 === 0) {
        const fps = Math.round(1000 / dt);
        document.getElementById('fps').textContent = `FPS: ${fps}`;
    }

    root.wasm.exports.update();

    requestAnimationFrame(update);
}

const encode = {
    str: function(input) {
        const buffer = new TextEncoder().encode(input);
        const ptr = root.wasm.exports.allocUint8(buffer.length + 1);
        const view = new Uint8Array(root.wasm.exports.memory.buffer, ptr, buffer.length + 1);
        view.set(buffer);
        view[buffer.length] = 0;
        return ptr;
    },
};

const decode = {
    str: function(ptr, len) {
        return new TextDecoder().decode(
            new Uint8Array(root.wasm.exports.memory.buffer, ptr, len)
        );
    },

    array: {
        Uint32: function(ptr, len) {
            let array = [];
            const ids = new Uint32Array(root.wasm.exports.memory.buffer, ptr, len);

            for (let i = 0; i < len; i++) array.push(ids[i]);

            return array;
        },

        Handle: function(ptr, len) {
            let array = [];
            const ids = new Uint32Array(root.wasm.exports.memory.buffer, ptr, len);

            for (let i = 0; i < len; i++) {
                const item = root.handles.get(ids[i]);
                console.assert(typeof item !== 'undefined', `Invalid (${ids[i]}) handle into pointer`);
                array.push(item);
            }

            return array;
        },
    },

    TextureFormat: function(ptr, len) { return this.str(ptr, len); },
    TextureDimension: function(ptr, len) { return this.str(ptr, len); },
    TextureViewDimension: function(ptr, len) { return this.str(ptr, len); },
    TextureAspect: function(ptr, len) { return this.str(ptr, len); },
    AddressMode: function(ptr, len) { return this.str(ptr, len); },
    FilterMode: function(ptr, len) { return this.str(ptr, len); },
    MipmapFilterMode: function(ptr, len) { return this.str(ptr, len); },
    LoadOp: function(ptr, len) { return this.str(ptr, len); },
    StoreOp: function(ptr, len) { return this.str(ptr, len); },
    VertexFormat: function(ptr, len) { return this.str(ptr, len); },
    VertexStepMode: function(ptr, len) { return this.str(ptr, len); },
    BlendOperation: function(ptr, len) { return this.str(ptr, len); },
    BlendFactor: function(ptr, len) { return this.str(ptr, len); },
    PrimitiveTopology: function(ptr, len) { return this.str(ptr, len); },
    FrontFace: function(ptr, len) { return this.str(ptr, len); },
    CullMode: function(ptr, len) { return this.str(ptr, len); },
    IndexFormat: function(ptr, len) { return this.str(ptr, len); },
    ErrorFilter: function(ptr, len) { return this.str(ptr, len); },

    view: {
        Handle: function(view, offset) {
            const resource_id = view.getUint32(offset, true);
            const resource = root.handles.get(resource_id);
            console.assert(typeof resource !== 'undefined', `Invalid resource (${resource_id}) handle`);
            return resource;
        },

        BindGroupEntry: function(view, offset) {
            return {
                offset: Number(view.getBigUint64(offset, true)),
                size: Number(view.getBigUint64(offset + 8, true)),
                binding: view.getUint32(offset + 16, true),
                type: view.getUint32(offset + 20, true), // 0 = buffer, 1 = texture_view
                resource: this.Handle(view, offset + 24),
            };
        },

        BindGroupLayoutEntry: function(view, offset) {
            return {
                visibility: Number(view.getBigUint64(offset, true)),
                binding: view.getUint32(offset + 8, true),
                type: view.getUint32(offset + 12, true), // 0 = uniform buffer, 1 = 2d texture, 2 = 2d array texture, 3 = sampler
            };
        },

        TextureFormat: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined TextureFormat`);
            return decode.TextureFormat(ptr, len);
        },

        TextureDimension: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined TextureDimension`);
            return decode.TextureDimension(ptr, len);
        },

        TextureViewDimension: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined TextureViewDimension`);
            return decode.TextureViewDimension(ptr, len);
        },

        TextureAspect: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined TextureAspect`);
            return decode.TextureAspect(ptr, len);
        },

        TextureViewDescriptor: function(view) {
            return {
                baseMipLevel: view.getUint32(0, true),
                mipLevelCount: view.getUint32(4, true),
                baseArrayLayer: view.getUint32(8, true),
                arrayLayerCount: view.getUint32(12, true),
                format: this.TextureFormat(view, 16),
                dimension: this.TextureViewDimension(view, 24),
                aspect: this.TextureAspect(view, 32),
            };
        },

        Extent3D: function(view, offset) {
            return {
                width: view.getUint32(offset, true),
                height: view.getUint32(offset + 4, true),
                depthOrArrayLayers: view.getUint32(offset + 8, true),
            };
        },

        TextureDescriptor: function(view) {
            return {
                usage: Number(view.getBigUint64(0, true)),
                size: this.Extent3D(view, 8),
                sampleCount: view.getUint32(20, true),
                mipLevelCount: view.getUint32(24, true),
                format: this.TextureFormat(view, 28),
                dimension: this.TextureDimension(view, 36),
            };
        },

        AddressMode: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined AddressMode`);
            return decode.AddressMode(ptr, len);
        },

        FilterMode: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined FilterMode`);
            return decode.FilterMode(ptr, len);
        },

        MipmapFilterMode: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined MipmapFilterMode`);
            return decode.MipmapFilterMode(ptr, len);
        },

        SamplerDescriptor: function(view) {
            return {
                addressModeU: this.AddressMode(view, 0),
                addressModeV: this.AddressMode(view, 8),
                addressModeW: this.AddressMode(view, 16),
                magFilter: this.FilterMode(view, 24),
                minFilter: this.FilterMode(view, 32),
                mipmapFilter: this.MipmapFilterMode(view, 40),
                maxAnisotropy: view.getUint32(48, true),
            };
        },

        LoadOp: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined LoadOp`);
            return decode.LoadOp(ptr, len);
        },

        StoreOp: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined StoreOp`);
            return decode.StoreOp(ptr, len);
        },

        RenderPassDescriptor: function(descriptor_view, texture_view) {
            return {
                colorAttachments: [{
                    view: texture_view,
                    clearValue: [0, 0, 0, 0],
                    loadOp: this.LoadOp(descriptor_view, 0),
                    storeOp: this.StoreOp(descriptor_view, 8),
                }],
            };
        },

        VertexFormat: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined VertexFormat`);
            return decode.VertexFormat(ptr, len);
        },

        VertexAttribute: function(view, offset) {
            return {
                offset: Number(view.getBigUint64(offset, true)),
                shaderLocation: view.getUint32(offset + 8, true),
                format: this.VertexFormat(view, offset + 12),
            };
        },

        VertexStepMode: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined VertexStepMode`);
            return decode.VertexStepMode(ptr, len);
        },

        VertexBufferLayout: function(view, offset) {
            const array_stride = Number(view.getBigUint64(offset, true));
            const vertex_attributes_ptr = view.getUint32(offset + 16, true);
            const vertex_attributes_len = view.getUint32(offset + 20, true);
            const vertex_attribute_size = Number(root.wasm.exports.sizeOfVertexAttribute());

            let vertex_attributes = [];
            const vertex_attributes_view = new DataView(root.wasm.exports.memory.buffer, vertex_attributes_ptr, vertex_attributes_len * vertex_attribute_size);

            for (let i = 0; i < vertex_attributes_len; i++) {
                vertex_attributes.push(this.VertexAttribute(vertex_attributes_view, i * vertex_attribute_size));
            }

            return {
                arrayStride: array_stride,
                stepMode: this.VertexStepMode(view, offset + 8),
                attributes: vertex_attributes,
            };
        },

        BlendOperation: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined BlendOperation`);
            return decode.BlendOperation(ptr, len);
        },

        BlendFactor: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined BlendFactor`);
            return decode.BlendFactor(ptr, len);
        },

        BlendComponent: function(view, offset) {
            return {
                operation: this.BlendOperation(view, offset),
                srcFactor: this.BlendFactor(view, offset + 8),
                dstFactor: this.BlendFactor(view, offset + 16),
            };
        },

        BlendState: function(view, offset) {
            return {
                color: this.BlendComponent(view, offset),
                alpha: this.BlendComponent(view, offset + 24),
            };
        },

        ColorTargetState: function(view, offset) {
            return {
                writeMask: Number(view.getBigUint64(offset, true)),
                blend: this.BlendState(view, offset + 8),
                format: this.TextureFormat(view, offset + 56),
            };
        },

        PrimitiveTopology: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined PrimitiveTopology`);
            return decode.PrimitiveTopology(ptr, len);
        },

        FrontFace: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined FrontFace`);
            return decode.FrontFace(ptr, len);
        },

        CullMode: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            console.assert(len > 0, `Undefined CullMode`);
            return decode.CullMode(ptr, len);
        },

        IndexFormat: function(view, offset) {
            const ptr = view.getUint32(offset, true);
            const len = view.getUint32(offset + 4, true);
            let val = undefined;
            if (len > 0) val = decode.IndexFormat(ptr, len);
            return val;
        },

        PrimitiveState: function(view) {
            return {
                topology: this.PrimitiveTopology(view, 0),
                frontFace: this.FrontFace(view, 8),
                cullMode: this.CullMode(view, 16),
                stripIndexFormat: this.IndexFormat(view, 24),
            };
        },

        VertexState: function(view) {
            const vertex_buffer_layout_size = Number(root.wasm.exports.sizeOfVertexBufferLayout());
            const vertex_buffer_layouts_ptr = view.getUint32(0, true);
            const vertex_buffer_layouts_len = view.getUint32(4, true);
            let vertex_buffer_layouts = [];
            const vertex_buffer_layouts_view = new DataView(root.wasm.exports.memory.buffer, vertex_buffer_layouts_ptr, vertex_buffer_layouts_len * vertex_buffer_layout_size);

            for (let i = 0; i < vertex_buffer_layouts_len; i++) {
                vertex_buffer_layouts.push(this.VertexBufferLayout(vertex_buffer_layouts_view, i * vertex_buffer_layout_size));
            }

            return {
                module: this.Handle(view, 8),
                entryPoint: 'main',
                buffers: vertex_buffer_layouts,
            };
        },

        FragmentState: function(view) {
            const color_target_states_ptr = view.getUint32(0, true);
            const color_target_states_len = view.getUint32(4, true);
            const color_target_state_size = Number(root.wasm.exports.sizeOfColorTargetState());

            let color_target_states = [];
            const color_target_states_view = new DataView(root.wasm.exports.memory.buffer, color_target_states_ptr, color_target_states_len * color_target_state_size);

            for (let i = 0; i < color_target_states_len; i++) {
                color_target_states.push(this.ColorTargetState(color_target_states_view, i * color_target_state_size));
            }

            return {
                module: this.Handle(view, 8),
                entryPoint: 'main',
                targets: color_target_states,
            };
        },

        Origin3D: function(view, offset) {
            return {
                x: view.getUint32(offset, true),
                y: view.getUint32(offset + 4, true),
                z: view.getUint32(offset + 8, true),
            };
        },

        TexelCopyTextureInfo: function(view) {
            return {
                texture: this.Handle(view, 0),
                mipLevel: view.getUint32(4, true),
                origin: this.Origin3D(view, 8),
                aspect: this.TextureAspect(view, 20),
            };
        },

        TexelCopyBufferLayout: function(view) {
            return {
                offset: Number(view.getBigUint64(0, true)),
                bytesPerRow: view.getUint32(8, true),
                rowsPerImage: view.getUint32(12, true),
            };
        },

        Color: function(view) {
            return {
                r: view.getFloat64(0, true),
                g: view.getFloat64(8, true),
                b: view.getFloat64(16, true),
                a: view.getFloat64(24, true),
            };
        },
    },
};

var wasm_imports = {
    env: {
        jsConsoleWrite: function(ptr, len) {
            root.console_buffer += decode.str(ptr, len);
        },

        jsConsoleFlush: function(mode) {
            switch (mode) {
                case 0:
                    if (root.console_buffer !== '') {
                        console.log(root.console_buffer.trim());
                        root.console_buffer = '';
                    }
                    break;
                case 1:
                    root.console_buffer = '';
                    break;
                case 2:
                    root.flushConsoleBufferAndThrowError(null);
                    break;
                case 3:
                    root.flushConsoleBufferAndThrowError('ZigError');
                    break;
                case 4:
                    root.flushConsoleBufferAndThrowError('ZigPanic');
                    break;
                case 5:
                    root.flushConsoleBufferAndThrowError('ZigAssertionFailure');
                    break;
                default:
                    throw new Error(`Unknown flush mode (${mode}) into jsConsoleFlush`);
                    break;
            }
        },

        jsTimeNow: function() {
            if (root.timestamp === null) {
                const date = new Date();
                return date.getTime();
            }
            return root.timestamp;
        },

        jsRequestAnimationFrame: function() {
            requestAnimationFrame(update);
        },

        jsGpuGetAdapter: function() {
            if (root.adapter_id === null) throw new Error(`Adapter is not initialized`);
            return root.adapter_id;
        },

        jsGpuGetDevice: function() {
            if (root.device_id === null) throw new Error(`Device is not initialized`);
            return root.device_id;
        },

        jsGpuContextConfigure: function(context_id, device_id, texture_format_ptr, texture_format_len) {
            const context = root.handles.get(context_id);
            const device = root.handles.get(device_id);
            console.assert(typeof context !== 'undefined' && typeof device !== 'undefined', `Invalid context (${context_id}) or device (${device_id}) handle`);

            const texture_format = decode.TextureFormat(texture_format_ptr, texture_format_len);

            context.configure({
                device: device,
                format: texture_format,
                alphaMode: 'opaque',
            });
        },

        jsGpuContextGetCurrentTexture: function(context_id) {
            const context = root.handles.get(context_id);
            console.assert(typeof context !== 'undefined', `Invalid context (${context_id}) handle`);

            return root.handles.create(context.getCurrentTexture());
        },

        jsGpuRelease: function(resource_id) {
            const resource = root.handles.get(resource_id);
            console.assert(typeof resource !== 'undefined', `Invalid resource (${resource_id}) handle`);

            root.handles.release(resource_id);
        },

        jsGpuInstanceRequestAdapter: function(instance_id, cb_handle) {
            const instance = root.handles.get(instance_id);
            console.assert(typeof instance !== 'undefined', `Invalid instance (${instance_id}) handle`);

            instance.requestAdapter().then((adapter) => {
                root.adapter_id = root.handles.create(adapter);
                root.wasm.exports.triggerCallback(cb_handle);
            }).catch((err) => {
                root.fail('jsGpuInstanceRequestAdapter', err);
            });
        },

        jsGpuInstanceGetPreferredSurfaceFormat: function(instance_id) {
            const instance = root.handles.get(instance_id);
            console.assert(typeof instance !== 'undefined', `Invalid instance (${instance_id}) handle`);

            return encode.str(instance.getPreferredCanvasFormat());
        },

        jsGpuAdapterRequestDevice: function(adapter_id, cb_handle) {
            const adapter = root.handles.get(adapter_id);
            console.assert(typeof adapter !== 'undefined', `Invalid adapter (${adapter_id}) handle`);

            adapter.requestDevice().then((device) => {
                root.device_id = root.handles.create(device);
                root.wasm.exports.triggerCallback(cb_handle);
            }).catch((err) => {
                root.fail('jsGpuAdapterRequestDevice', err);
            });
        },

        jsGpuDeviceCreateShaderModule: function(device_id, source_ptr, source_len) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            const source = decode.str(source_ptr, source_len);

            try {
                return root.handles.create(device.createShaderModule({ code: source }));
            } catch (err) {
                console.error('Shader compilation error:', err);
                console.error('Shader source:', source);
                throw new Error('Shader compilation failed');
            }
        },

        jsGpuDeviceCreatePipelineLayout: function(device_id, bind_group_layouts_ptr, bind_group_layouts_len) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            const bind_group_layouts = decode.array.Handle(bind_group_layouts_ptr, bind_group_layouts_len);

            return root.handles.create(device.createPipelineLayout({
                bindGroupLayouts: bind_group_layouts,
            }));
        },

        jsGpuDeviceCreateRenderPipeline: function(device_id, pipeline_layout_id, vertex_state_ptr, fragment_state_ptr, primitive_state_ptr) {
            const device = root.handles.get(device_id);
            const pipeline_layout = root.handles.get(pipeline_layout_id);
            console.assert(typeof device !== 'undefined' && typeof pipeline_layout !== 'undefined', `Invalid device (${device_id}) or pipeline layout (${pipeline_layout_id}) handle`);

            const vertex_state_view = new DataView(root.wasm.exports.memory.buffer, vertex_state_ptr, Number(root.wasm.exports.sizeOfVertexState()));
            const fragment_state_view = new DataView(root.wasm.exports.memory.buffer, fragment_state_ptr, Number(root.wasm.exports.sizeOfFragmentState()));
            const primitive_state_view = new DataView(root.wasm.exports.memory.buffer, primitive_state_ptr, Number(root.wasm.exports.sizeOfPrimitiveState()));

            const vertex = decode.view.VertexState(vertex_state_view);
            const fragment = decode.view.FragmentState(fragment_state_view);
            const primitive = decode.view.PrimitiveState(primitive_state_view);

            return root.handles.create(device.createRenderPipeline({
                layout: pipeline_layout,
                vertex: vertex,
                fragment: fragment,
                primitive: primitive,
            }));
        },

        jsGpuDeviceCreateCommandEncoder: function(device_id) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            return root.handles.create(device.createCommandEncoder());
        },

        jsGpuDeviceCreateTexture: function(device_id, descriptor_ptr) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            const descriptor_view = new DataView(root.wasm.exports.memory.buffer, descriptor_ptr, Number(root.wasm.exports.sizeOfTextureDescriptor()));
            const descriptor = decode.view.TextureDescriptor(descriptor_view);

            return root.handles.create(device.createTexture(descriptor));
        },

        jsGpuDeviceCreateBuffer: function(device_id, BUFFER_SIZE_BIGINT, BUFFER_USAGE_BIGINT) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            return root.handles.create(device.createBuffer({
                size: Number(BUFFER_SIZE_BIGINT),
                usage: Number(BUFFER_USAGE_BIGINT),
            }));
        },

        jsGpuDestroyBuffer: function(buffer_id) {
            const buffer = root.handles.get(buffer_id);
            console.assert(typeof buffer !== 'undefined', `Invalid buffer (${buffer_id}) handle`);

            buffer.destroy();
        },

        jsGpuDeviceCreateBindGroupLayout: function(device_id, bind_group_layout_entries_ptr, bind_group_layout_entries_len) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            const entry_size = Number(root.wasm.exports.sizeOfBindGroupLayoutEntry());
            let bind_group_layout_entries = [];
            const bind_group_layout_entries_view = new DataView(root.wasm.exports.memory.buffer, bind_group_layout_entries_ptr, bind_group_layout_entries_len * entry_size);

            for (let i = 0; i < bind_group_layout_entries_len; i++) {
                const decoded = decode.view.BindGroupLayoutEntry(bind_group_layout_entries_view, i * entry_size);

                const entry = {
                    binding: decoded.binding,
                    visibility: decoded.visibility,
                };

                switch (decoded.type) {
                        // Uniform buffer binding
                    case 0:
                        entry.buffer = {
                            type: 'uniform',
                        };
                        break;
                        // 2d Texture binding
                    case 1:
                        entry.texture = {
                            sampleType: 'float',
                            viewDimension: '2d',
                            multisampled: false,
                        };
                        break;
                        // 2d-array Texture binding
                    case 2:
                        entry.texture = {
                            sampleType: 'float',
                            viewDimension: '2d-array',
                            multisampled: false,
                        };
                        break;
                        // Sampler binding
                    case 3:
                        entry.sampler = {
                            type: 'filtering',
                        };
                        break;
                    default:
                        throw new Error(`Unknown entry type (${decoded.type}) into jsGpuDeviceCreateBindGroupLayout`);
                        break;
                }

                bind_group_layout_entries.push(entry);
            }

            return root.handles.create(device.createBindGroupLayout({
                entries: bind_group_layout_entries,
            }));
        },

        jsGpuDeviceCreateBindGroup: function(device_id, bind_group_layout_id, bind_group_entries_ptr, bind_group_entries_len) {
            const device = root.handles.get(device_id);
            const bind_group_layout = root.handles.get(bind_group_layout_id);
            console.assert(typeof device !== 'undefined' && typeof bind_group_layout !== 'undefined', `Invalid device (${device_id}) or bind group layout (${bind_group_layout_id}) handle`);

            let bind_group_entries = [];
            const entry_size = Number(root.wasm.exports.sizeOfBindGroupEntry());
            const bind_group_entries_view = new DataView(root.wasm.exports.memory.buffer, bind_group_entries_ptr, bind_group_entries_len * entry_size);

            for (let i = 0; i < bind_group_entries_len; i++) {
                const decoded = decode.view.BindGroupEntry(bind_group_entries_view, i * entry_size);

                const entry = { binding: decoded.binding };

                switch (decoded.type) {
                        // Buffer binding
                    case 0:
                        entry.resource = {
                            buffer: decoded.resource,
                            offset: decoded.offset,
                            size: decoded.size,
                        };
                        break;
                        // Texture view or Sampler binding
                    case 1:
                    case 2:
                        entry.resource = decoded.resource;
                        break;
                    default:
                        throw new Error(`Unknown entry type (${decoded.type}) into jsGpuDeviceCreateBindGroup`);
                        break;
                }

                bind_group_entries.push(entry);
            }

            return root.handles.create(device.createBindGroup({
                layout: bind_group_layout,
                entries: bind_group_entries,
            }));
        },

        jsGpuDeviceCreateSampler: function(device_id, descriptor_ptr) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            const descriptor_view = new DataView(root.wasm.exports.memory.buffer, descriptor_ptr, Number(root.wasm.exports.sizeOfSamplerDescriptor()));
            const descriptor = decode.view.SamplerDescriptor(descriptor_view);

            return root.handles.create(device.createSampler(descriptor));
        },

        jsGpuDeviceGetQueue: function(device_id) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            return root.handles.create(device.queue);
        },

        jsGpuDevicePushErrorScope: function(device_id, filter_ptr, filter_len) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            const filter = decode.ErrorFilter(filter_ptr, filter_len);

            device.pushErrorScope(filter);
        },

        jsGpuDevicePopErrorScope: function(device_id, cb_handle) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            device.popErrorScope().then((error) => {
                root.error_scope = error;
                root.wasm.exports.triggerCallback(cb_handle);
                root.error_scope = null;
            });
        },

        jsGpuDeviceThrowErrorScope: function(device_id) {
            const device = root.handles.get(device_id);
            console.assert(typeof device !== 'undefined', `Invalid device (${device_id}) handle`);

            if (root.error_scope !== null) throw root.error_scope;
        },

        jsGpuTextureGetWidth: function(texture_id) {
            const texture = root.handles.get(texture_id);
            console.assert(typeof texture !== 'undefined', `Invalid texture (${texture_id}) handle`);

            return texture.width;
        },

        jsGpuTextureGetHeight: function(texture_id) {
            const texture = root.handles.get(texture_id);
            console.assert(typeof texture !== 'undefined', `Invalid texture (${texture_id}) handle`);

            return texture.height;
        },

        jsGpuTextureGetDepthOrArrayLayers: function(texture_id) {
            const texture = root.handles.get(texture_id);
            console.assert(typeof texture !== 'undefined', `Invalid texture (${texture_id}) handle`);

            return texture.depthOrArrayLayers;
        },

        jsGpuTextureGetMipLevelCount: function(texture_id) {
            const texture = root.handles.get(texture_id);
            console.assert(typeof texture !== 'undefined', `Invalid texture (${texture_id}) handle`);

            return texture.mipLevelCount;
        },

        jsGpuTextureGetFormat: function(texture_id) {
            const texture = root.handles.get(texture_id);
            console.assert(typeof texture !== 'undefined', `Invalid texture (${texture_id}) handle`);

            return encode.str(texture.format);
        },

        jsGpuTextureGetDimension: function(texture_id) {
            const texture = root.handles.get(texture_id);
            console.assert(typeof texture !== 'undefined', `Invalid texture (${texture_id}) handle`);

            return encode.str(texture.dimension);
        },

        jsGpuTextureCreateView: function(texture_id, descriptor_ptr) {
            const texture = root.handles.get(texture_id);
            console.assert(typeof texture !== 'undefined', `Invalid texture (${texture_id}) handle`);

            const descriptor_view = new DataView(root.wasm.exports.memory.buffer, descriptor_ptr, Number(root.wasm.exports.sizeOfTextureViewDescriptor()));
            const descriptor = decode.view.TextureViewDescriptor(descriptor_view);

            return root.handles.create(texture.createView(descriptor));
        },

        jsGpuCommandEncoderBeginRenderPass: function(command_encoder_id, texture_view_id, descriptor_ptr) {
            const command_encoder = root.handles.get(command_encoder_id);
            const texture_view = root.handles.get(texture_view_id);
            console.assert(typeof command_encoder !== 'undefined' && typeof texture_view !== 'undefined', `Invalid command encoder (${command_encoder_id}) or texture view (${texture_view_id}) handle`);

            const descriptor_view = new DataView(root.wasm.exports.memory.buffer, descriptor_ptr, Number(root.wasm.exports.sizeOfRenderPassDescriptor()));
            const descriptor = decode.view.RenderPassDescriptor(descriptor_view, texture_view);

            return root.handles.create(command_encoder.beginRenderPass(descriptor));
        },

        jsGpuCommandEncoderFinish: function(command_encoder_id) {
            const command_encoder = root.handles.get(command_encoder_id);
            console.assert(typeof command_encoder !== 'undefined', `Invalid command encoder (${command_encoder_id}) handle`);

            return root.handles.create(command_encoder.finish());
        },

        jsGpuRenderPassEncoderSetPipeline: function(render_pass_encoder_id, render_pipeline_id) {
            const render_pass_encoder = root.handles.get(render_pass_encoder_id);
            const render_pipeline = root.handles.get(render_pipeline_id);
            console.assert(typeof render_pass_encoder !== 'undefined' && typeof render_pipeline !== 'undefined', `Invalid render pass encoder (${render_pass_encoder_id}) or render pipeline (${render_pipeline_id}) handle`);

            render_pass_encoder.setPipeline(render_pipeline);
        },

        jsGpuRenderPassEncoderSetVertexBuffer: function(render_pass_encoder_id, slot, vertex_buffer_id, OFFSET_BIGINT, SIZE_BIGINT) {
            const render_pass_encoder = root.handles.get(render_pass_encoder_id);
            const vertex_buffer = root.handles.get(vertex_buffer_id);
            console.assert(typeof render_pass_encoder !== 'undefined' && typeof vertex_buffer !== 'undefined', `Invalid render pass encoder (${render_pass_encoder_id}) or vertex buffer (${vertex_buffer_id}) handle`);

            render_pass_encoder.setVertexBuffer(slot, vertex_buffer, Number(OFFSET_BIGINT), Number(SIZE_BIGINT));
        },

        jsGpuRenderPassEncoderSetIndexBuffer: function(render_pass_encoder_id, index_buffer_id, index_format_ptr, index_format_len, OFFSET_BIGINT, SIZE_BIGINT) {
            const render_pass_encoder = root.handles.get(render_pass_encoder_id);
            const index_buffer = root.handles.get(index_buffer_id);
            console.assert(typeof render_pass_encoder !== 'undefined' && typeof index_buffer !== 'undefined', `Invalid render pass encoder (${render_pass_encoder_id}) or index buffer (${index_buffer_id}) handle`);

            const index_format = decode.IndexFormat(index_format_ptr, index_format_len);

            render_pass_encoder.setIndexBuffer(index_buffer, index_format, Number(OFFSET_BIGINT), Number(SIZE_BIGINT));
        },

        jsGpuRenderPassEncoderSetBindGroup: function(render_pass_encoder_id, index, bind_group_id, dynamic_offsets_ptr, dynamic_offsets_len) {
            const render_pass_encoder = root.handles.get(render_pass_encoder_id);
            const bind_group = root.handles.get(bind_group_id);
            console.assert(typeof render_pass_encoder !== 'undefined' && typeof bind_group !== 'undefined', `Invalid render pass encoder (${render_pass_encoder_id}) or bind group (${bind_group_id}) handle`);

            const dynamic_offsets = decode.array.Uint32(dynamic_offsets_ptr, dynamic_offsets_len);

            render_pass_encoder.setBindGroup(index, bind_group, dynamic_offsets);
        },

        jsGpuRenderPassEncoderSetScissorRect: function(render_pass_encoder_id, x, y, width, height) {
            const render_pass_encoder = root.handles.get(render_pass_encoder_id);
            console.assert(typeof render_pass_encoder !== 'undefined', `Invalid render pass encoder (${render_pass_encoder_id}) handle`);

            render_pass_encoder.setScissorRect(x, y, width, height);
        },

        jsGpuRenderPassEncoderSetViewport: function(render_pass_encoder_id, x, y, width, height, min_depth, max_depth) {
            const render_pass_encoder = root.handles.get(render_pass_encoder_id);
            console.assert(typeof render_pass_encoder !== 'undefined', `Invalid render pass encoder (${render_pass_encoder_id}) handle`);

            render_pass_encoder.setViewport(x, y, width, height, min_depth, max_depth);
        },

        jsGpuRenderPassEncoderSetBlendConstant: function(render_pass_encoder_id, color_ptr) {
            const render_pass_encoder = root.handles.get(render_pass_encoder_id);
            console.assert(typeof render_pass_encoder !== 'undefined', `Invalid render pass encoder (${render_pass_encoder_id}) handle`);

            const color_view = new DataView(root.wasm.exports.memory.buffer, color_ptr, Number(root.wasm.exports.sizeOfColor()));
            const color = decode.view.Color(color_view);

            render_pass_encoder.setBlendConstant(color);
        },

        jsGpuRenderPassEncoderDrawIndexed: function(render_pass_encoder_id, index_count, instance_count, first_index, base_vertex, first_instance) {
            const render_pass_encoder = root.handles.get(render_pass_encoder_id);
            console.assert(typeof render_pass_encoder !== 'undefined', `Invalid render pass encoder (${render_pass_encoder_id}) handle`);

            render_pass_encoder.drawIndexed(index_count, instance_count, first_index, base_vertex, first_instance);
        },

        jsGpuRenderPassEncoderEnd: function(render_pass_encoder_id) {
            const render_pass_encoder = root.handles.get(render_pass_encoder_id);
            console.assert(typeof render_pass_encoder !== 'undefined', `Invalid render pass encoder (${render_pass_encoder_id}) handle`);

            render_pass_encoder.end();
        },

        jsGpuQueueSubmit: function(queue_id, command_buffers_ptr, command_buffers_len) {
            const queue = root.handles.get(queue_id);
            console.assert(typeof queue !== 'undefined', `Invalid queue (${queue_id}) handle`);

            const command_buffers = decode.array.Handle(command_buffers_ptr, command_buffers_len);

            queue.submit(command_buffers);
        },

        jsGpuQueueWriteBuffer: function(queue_id, buffer_id, BUFFER_OFFSET_BIGINT, data_ptr, data_len, DATA_OFFSET_BIGINT, SIZE_BIGINT) {
            const queue = root.handles.get(queue_id);
            const buffer = root.handles.get(buffer_id);
            console.assert(typeof queue !== 'undefined' && typeof buffer !== 'undefined', `Invalid queue (${queue_id}) or buffer (${buffer_id}) handle`);

            const data = new Uint8Array(root.wasm.exports.memory.buffer, data_ptr, data_len);

            queue.writeBuffer(buffer, Number(BUFFER_OFFSET_BIGINT), data, Number(DATA_OFFSET_BIGINT), Number(SIZE_BIGINT));
        },

        jsGpuQueueWriteTexture: function(queue_id, info_ptr, data_ptr, data_len, data_layout_ptr, size_extent_ptr) {
            const queue = root.handles.get(queue_id);
            console.assert(typeof queue !== 'undefined', `Invalid queue (${queue_id}) handle`);

            const info_view = new DataView(root.wasm.exports.memory.buffer, info_ptr, Number(root.wasm.exports.sizeOfTexelCopyTextureInfo()));
            const info = decode.view.TexelCopyTextureInfo(info_view);

            const data_layout_view = new DataView(root.wasm.exports.memory.buffer, data_layout_ptr, Number(root.wasm.exports.sizeOfTexelCopyBufferLayout()));
            const data_layout = decode.view.TexelCopyBufferLayout(data_layout_view);

            const size_extent_view = new DataView(root.wasm.exports.memory.buffer, size_extent_ptr, Number(root.wasm.exports.sizeOfExtent3D()));
            const size_extent = decode.view.Extent3D(size_extent_view, 0);

            const data = new Uint8Array(root.wasm.exports.memory.buffer, data_ptr, data_len);

            queue.writeTexture(info, data, data_layout, size_extent);
        },

        jsPlatformGetWindow: function() {
            return root.handles.create(window);
        },

        jsPlatformWindowGetCanvas: function(win_id) {
            const win = root.handles.get(win_id);
            console.assert(typeof win !== 'undefined', `Invalid window (${win_id}) handle`);

            return root.handles.create(win.document.getElementById('canvas'));
        },

        jsPlatformWindowGetGpuInstance: function(win_id) {
            const win = root.handles.get(win_id);
            console.assert(typeof win !== 'undefined', `Invalid window (${win_id}) handle`);

            if (win.navigator.gpu === null) {
                status('WebGPU not supported');
                throw new Error('WebGPU not supported');
            }

            return root.handles.create(win.navigator.gpu);
        },

        jsPlatformWindowListenEvent: function(win_id, event_ptr, event_len) {
            const win = root.handles.get(win_id);
            console.assert(typeof win !== 'undefined', `Invalid window (${win_id}) handle`);

            const event = decode.str(event_ptr, event_len);

            win.addEventListener(event, (win_event) => {
                root.event = win_event;
                root.wasm.exports.onWindowEvent(encode.str(win_event.type));
            });
        },

        jsPlatformWindowGetDevicePixelRatio: function(win_id) {
            const win = root.handles.get(win_id);
            console.assert(typeof win !== 'undefined', `Invalid window (${win_id}) handle`);

            return win.devicePixelRatio || 1;
        },

        jsPlatformCanvasGetGpuContext: function(canvas_id) {
            const canvas = root.handles.get(canvas_id);
            console.assert(typeof canvas !== 'undefined', `Invalid canvas (${canvas_id}) handle`);

            return root.handles.create(canvas.getContext('webgpu'));
        },

        jsPlatformCanvasResize: function(canvas_id, width, height, dpr) {
            const canvas = root.handles.get(canvas_id);
            console.assert(typeof canvas !== 'undefined', `Invalid canvas (${canvas_id}) handle`);

            canvas.width = Math.floor(width * dpr);
            canvas.height = Math.floor(height * dpr);
        },

        jsPlatformCanvasListenEvent: function(canvas_id, event_ptr, event_len) {
            const canvas = root.handles.get(canvas_id);
            console.assert(typeof canvas !== 'undefined', `Invalid canvas (${canvas_id}) handle`);

            const event = decode.str(event_ptr, event_len);

            canvas.addEventListener(event, (canvas_event) => {
                root.event = canvas_event;
                root.wasm.exports.onCanvasEvent(encode.str(canvas_event.type));
            });
        },

        jsPlatformCanvasGetBoundingClientRectWidth: function(canvas_id) {
            const canvas = root.handles.get(canvas_id);
            console.assert(typeof canvas !== 'undefined', `Invalid canvas (${canvas_id}) handle`);

            return canvas.getBoundingClientRect().width;
        },

        jsPlatformCanvasGetBoundingClientRectHeight: function(canvas_id) {
            const canvas = root.handles.get(canvas_id);
            console.assert(typeof canvas !== 'undefined', `Invalid canvas (${canvas_id}) handle`);

            return canvas.getBoundingClientRect().height;
        },

        jsPlatformCanvasGetBoundingClientRectLeft: function(canvas_id) {
            const canvas = root.handles.get(canvas_id);
            console.assert(typeof canvas !== 'undefined', `Invalid canvas (${canvas_id}) handle`);

            return canvas.getBoundingClientRect().left;
        },

        jsPlatformCanvasGetBoundingClientRectTop: function(canvas_id) {
            const canvas = root.handles.get(canvas_id);
            console.assert(typeof canvas !== 'undefined', `Invalid canvas (${canvas_id}) handle`);

            return canvas.getBoundingClientRect().top;
        },

        jsPlatformGetClipboard: function() {
            return root.handles.create(navigator.clipboard);
        },

        jsPlatformClipboardWriteText: function(clipboard_id, text_ptr, text_len) {
            const clipboard = root.handles.get(clipboard_id);
            console.assert(typeof clipboard !== 'undefined', `Invalid clipboard (${clipboard_id}) handle`);

            const text = decode.str(text_ptr, text_len);

            clipboard.writeText(text).then(() => {});
        },

        jsPlatformKeyboardEventGetCodepoint: function() {
            let codepoint = root.event.key.charCodeAt(0);
            if (codepoint < 0x7f && root.event.key.length > 1) codepoint = 0;
            return codepoint;
        },

        jsPlatformKeyboardEventGetCode: function() {
            return encode.str(root.event.code);
        },

        // Here we ignore CapsLock and NumLock modifiers for simplicity
        jsPlatformKeyboardEventGetModifierBits: function() {
            let modifier_bits = 0;
            if (root.event.shiftKey) modifier_bits |= 0x0001;
            if (root.event.ctrlKey) modifier_bits |= 0x0002;
            if (root.event.altKey) modifier_bits |= 0x0004;
            if (root.event.metaKey) modifier_bits |= 0x0008;
            return modifier_bits;
        },

        jsPlatformMouseButtonEventGetButton: function() {
            return root.event.button;
        },

        jsPlatformMouseMoveEventGetClientX: function() {
            return root.event.clientX;
        },

        jsPlatformMouseMoveEventGetClientY: function() {
            return root.event.clientY;
        },

        jsPlatformWheelEventGetDeltaMode: function() {
            return root.event.deltaMode;
        },

        jsPlatformWheelEventGetDeltaX: function() {
            return root.event.deltaX;
        },

        jsPlatformWheelEventGetDeltaY: function() {
            return root.event.deltaY;
        },
    },
};

function initWasmModule(wasm_module) {
    root.wasm = wasm_module.instance;
    root.wasm.exports.init();
}

function initWasmInstance(wasm_bytes) {
    WebAssembly.instantiate(wasm_bytes, wasm_imports).then(initWasmModule);
}

function initWasmBytes(response) {
    if (!response.ok) throw new Error(`Failed to fetch spaceporn.wasm: ${response.status}`);
    response.arrayBuffer().then(initWasmInstance);
}

function main() {
    fetch(`spaceporn.wasm`).then(initWasmBytes);
}

// Start when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', main);
} else {
    main();
}
