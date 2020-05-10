//
//  MeshRenderer.swift
//  CastPrintSensor
//
//  Created by Uvis Štrauss on 04/04/2020.
//  Copyright © 2020 CastPrint. All rights reserved.
//

// swiftlint:disable identifier_name line_length force_unwrapping type_body_length explicit_init

let MAX_MESHES: Int = 30

class MeshRenderer: NSObject {

    enum RenderingMode: Int {

        case xRay = 0
        case perVertexColor
        case textured
        case lightedGray
    }

    struct PrivateData {

        var lightedGrayShader: LightedGrayShader?
        var perVertexColorShader: PerVertexColorShader?
        var xRayShader: XrayShader?
        var yCbCrTextureShader: YCbCrTextureShader?

        var numUploadedMeshes: Int = 0
        var numTriangleIndices = [Int](repeating: 0, count: MAX_MESHES)
        var numLinesIndices = [Int](repeating: 0, count: MAX_MESHES)

        var hasPerVertexColor: Bool = false
        var hasPerVertexNormals: Bool = false
        var hasPerVertexUV: Bool = false
        var hasTexture: Bool = false

        // Vertex buffer objects.
        var vertexVbo = [GLuint](repeating: 0, count: MAX_MESHES)
        var normalsVbo = [GLuint](repeating: 0, count: MAX_MESHES)
        var colorsVbo = [GLuint](repeating: 0, count: MAX_MESHES)
        var texcoordsVbo = [GLuint](repeating: 0, count: MAX_MESHES)
        var facesVbo = [GLuint](repeating: 0, count: MAX_MESHES)
        var linesVbo = [GLuint](repeating: 0, count: MAX_MESHES)

        // OpenGL Texture reference for y and chroma images.
        var lumaTexture: CVOpenGLESTexture?
        var chromaTexture: CVOpenGLESTexture?

        // OpenGL Texture cache for the color texture.
        var textureCache: CVOpenGLESTextureCache?

        // Texture unit to use for texture binding/rendering.
        var textureUnit: GLenum = GLenum(GL_TEXTURE3)

        // Current render mode.
        var currentRenderingMode: RenderingMode = .lightedGray

        internal init() {

            lightedGrayShader = LightedGrayShader()
            perVertexColorShader = PerVertexColorShader()
            xRayShader = XrayShader()
            yCbCrTextureShader = YCbCrTextureShader()
        }
    }

    var privD: PrivateData?

    override init() {

        self.privD = PrivateData.init()

    }

   func initializeGL(_ defaultTextureUnit: GLenum = GLenum(GL_TEXTURE3)) {

        privD!.textureUnit = defaultTextureUnit
        glGenBuffers( GLsizei(MAX_MESHES), &privD!.vertexVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &privD!.normalsVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &privD!.colorsVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &privD!.texcoordsVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &privD!.facesVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &privD!.linesVbo)
    }

  func releaseGLTextures() {

        if privD!.lumaTexture != nil {

            privD!.lumaTexture = nil
        }

        if privD!.chromaTexture != nil {

            privD!.chromaTexture = nil
        }

        if privD!.textureCache != nil {

            privD!.textureCache = nil
        }
    }

  func releaseGLBuffers() {

        for meshIndex in 0..<privD!.numUploadedMeshes {

            glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.vertexVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))

            glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.normalsVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))

            glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.colorsVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))

            glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.texcoordsVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))

            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), privD!.facesVbo[meshIndex])
            glBufferData( GLenum(GL_ELEMENT_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))

            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), privD!.linesVbo[meshIndex])
            glBufferData( GLenum(GL_ELEMENT_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))
        }
    }

    deinit {

        MeshRendererDestructor(self.privD!)

        self.privD = nil
    }

    func MeshRendererDestructor(_ privD: PrivateData) {

        if privD.vertexVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), privD.vertexVbo)
        }
        if privD.normalsVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), privD.normalsVbo)
        }
        if privD.colorsVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), privD.colorsVbo)
        }
        if privD.texcoordsVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), privD.texcoordsVbo)
        }
        if privD.facesVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), privD.facesVbo)
        }
        if privD.linesVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), privD.linesVbo)
        }

        releaseGLTextures()

        self.privD!.lightedGrayShader = nil
        self.privD!.perVertexColorShader = nil
        self.privD!.xRayShader = nil
        self.privD!.yCbCrTextureShader = nil
        self.privD!.numUploadedMeshes = 0
    }

   func clear() {

        if privD!.currentRenderingMode == RenderingMode.perVertexColor || privD!.currentRenderingMode == RenderingMode.textured {
            glClearColor(0.9, 0.9, 0.9, 1)
        } else if privD!.currentRenderingMode == RenderingMode.lightedGray {
            glClearColor(0.3, 0.3, 0.3, 1.0)
        } else {
            glClearColor(0.4, 0.4, 0.4, 1.0)
        }

        glClearDepthf(1)

        glClear( GLenum(GL_COLOR_BUFFER_BIT) | GLenum(GL_DEPTH_BUFFER_BIT))
    }

   func setRenderingMode(_ mode: RenderingMode) {
        privD!.currentRenderingMode = mode
    }

   func getRenderingMode() -> RenderingMode {
        return privD!.currentRenderingMode
    }

    func uploadMesh(_ mesh: STMesh) {

        let numUploads: Int = min(Int(mesh.numberOfMeshes()), Int(MAX_MESHES))
        privD!.numUploadedMeshes = min(Int(mesh.numberOfMeshes()), Int(MAX_MESHES))

        privD!.hasPerVertexColor = mesh.hasPerVertexColors()
        privD!.hasPerVertexNormals = mesh.hasPerVertexNormals()
        privD!.hasPerVertexUV = mesh.hasPerVertexUVTextureCoords()
        privD!.hasTexture = (mesh.meshYCbCrTexture() != nil)

        if privD!.hasTexture {
            let pixelBuffer = Unmanaged<CVImageBuffer>.takeUnretainedValue(mesh.meshYCbCrTexture())
            uploadTexture(pixelBuffer())
        }

        for meshIndex in 0..<numUploads {

            let numVertices: Int = Int(mesh.number(ofMeshVertices: Int32(meshIndex)))

            glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.vertexVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), numVertices * MemoryLayout<GLKVector3>.size, mesh.meshVertices(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))

            if privD!.hasPerVertexNormals {

                glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.normalsVbo[meshIndex])
                glBufferData( GLenum(GL_ARRAY_BUFFER), numVertices * MemoryLayout<GLKVector3>.size, mesh.meshPerVertexNormals(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))
            }

            if privD!.hasPerVertexColor {

                glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.colorsVbo[meshIndex])
                glBufferData( GLenum(GL_ARRAY_BUFFER), numVertices * MemoryLayout<GLKVector3>.size, mesh.meshPerVertexColors(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))
            }

            if privD!.hasPerVertexUV {

                glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.texcoordsVbo[meshIndex])
                glBufferData( GLenum(GL_ARRAY_BUFFER), numVertices * MemoryLayout<GLKVector2>.size, mesh.meshPerVertexUVTextureCoords(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))
            }

            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), privD!.facesVbo[meshIndex])
            glBufferData( GLenum(GL_ELEMENT_ARRAY_BUFFER), Int(mesh.number(ofMeshFaces: Int32(meshIndex))) * MemoryLayout<Int32>.size * 3, mesh.meshFaces(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))

            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), privD!.linesVbo[meshIndex])
            glBufferData( GLenum(GL_ELEMENT_ARRAY_BUFFER), Int(mesh.number(ofMeshLines: Int32(meshIndex))) * MemoryLayout<Int32>.size * 2, mesh.meshLines(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))

            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
            glBindBuffer( GLenum(GL_ARRAY_BUFFER), 0)

            privD!.numTriangleIndices[meshIndex] = Int(mesh.number(ofMeshFaces: Int32(meshIndex)) * 3)
            privD!.numLinesIndices[meshIndex] = Int(mesh.number(ofMeshLines: Int32(meshIndex)) * 2)
        }
    }

    func uploadTexture(_ pixelBuffer: CVImageBuffer) {

        let width = Int(CVPixelBufferGetWidth(pixelBuffer))
        let height = Int(CVPixelBufferGetHeight(pixelBuffer))

        let context: EAGLContext? = EAGLContext.current()
        assert(context != nil)

        releaseGLTextures()

        if privD!.textureCache == nil {

            let texError = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context!, nil, &privD!.textureCache)
            if texError != kCVReturnSuccess {
                NSLog("Error at CVOpenGLESTextureCacheCreate \(texError)")
            }
        }

        // Allow the texture cache to do internal cleanup.
        CVOpenGLESTextureCacheFlush(privD!.textureCache!, 0)

        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)

        // Activate the default texture unit.
        glActiveTexture(privD!.textureUnit)

        // Create a new Y texture from the video texture cache.
        var err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, privD!.textureCache!, pixelBuffer, nil, GLenum(GL_TEXTURE_2D), GL_RED_EXT, GLsizei(width), GLsizei(height), GLenum(GL_RED_EXT), GLenum(GL_UNSIGNED_BYTE), 0, &privD!.lumaTexture)

        if err != kCVReturnSuccess {
            NSLog("Error with CVOpenGLESTextureCacheCreateTextureFromImage: \(err)")
            return
        }

        // Set rendering properties for the new texture.
        glBindTexture(CVOpenGLESTextureGetTarget(privD!.lumaTexture!), CVOpenGLESTextureGetName(privD!.lumaTexture!))
        glTexParameterf( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameterf( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))

        // Activate the next texture unit for CbCr.
        glActiveTexture(privD!.textureUnit + 1)

        // Create a new CbCr texture from the video texture cache.
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, privD!.textureCache!, pixelBuffer, nil, GLenum(GL_TEXTURE_2D), GL_RG_EXT, Int32(width) / 2, Int32(height) / 2, GLenum(GL_RG_EXT), GLenum(GL_UNSIGNED_BYTE), 1, &privD!.chromaTexture)

        if err != kCVReturnSuccess {
            NSLog("Error with CVOpenGLESTextureCacheCreateTextureFromImage: \(err)")
            return
        }

        glBindTexture(CVOpenGLESTextureGetTarget(privD!.chromaTexture!), CVOpenGLESTextureGetName(privD!.chromaTexture!))
        glTexParameterf( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameterf( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))
        glBindTexture( GLenum(GL_TEXTURE_2D), 0)
    }

    func enableVertexBuffer(_ meshIndex: Int) {

        glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.vertexVbo[meshIndex])
        glEnableVertexAttribArray(CustomShader.Attrib.vertex.rawValue)
        glVertexAttribPointer(CustomShader.Attrib.vertex.rawValue, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    }

    func disableVertexBuffer(_ meshIndex: Int) {

        glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.vertexVbo[meshIndex])
        glDisableVertexAttribArray(CustomShader.Attrib.vertex.rawValue)
    }

    func enableNormalBuffer (_ meshIndex: Int) {

        glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.normalsVbo[meshIndex])
        glEnableVertexAttribArray(CustomShader.Attrib.normal.rawValue)
        glVertexAttribPointer(CustomShader.Attrib.normal.rawValue, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    }

    func disableNormalBuffer(_ meshIndex: Int) {

        glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.normalsVbo[meshIndex])
        glDisableVertexAttribArray(CustomShader.Attrib.normal.rawValue)
    }

    func enableVertexColorBuffer (_ meshIndex: Int) {

        glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.colorsVbo[meshIndex])
        glEnableVertexAttribArray(CustomShader.Attrib.color.rawValue)
        glVertexAttribPointer(CustomShader.Attrib.color.rawValue, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    }

    func disableVertexColorBuffer(_ meshIndex: Int) {

        glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.colorsVbo[meshIndex])
        glDisableVertexAttribArray(CustomShader.Attrib.color.rawValue)
    }

    func enableVertexTexcoordsBuffer (_ meshIndex: Int) {

        glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.texcoordsVbo[meshIndex])
        glEnableVertexAttribArray(CustomShader.Attrib.textCoord.rawValue)
        glVertexAttribPointer(CustomShader.Attrib.textCoord.rawValue, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    }

    func disableVertexTexcoordBuffer(_ meshIndex: Int) {

        glBindBuffer( GLenum(GL_ARRAY_BUFFER), privD!.texcoordsVbo[meshIndex])
        glDisableVertexAttribArray(CustomShader.Attrib.textCoord.rawValue)
    }

    func enableLinesElementBuffer (_ meshIndex: Int) {

        glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), privD!.linesVbo[meshIndex])
        glLineWidth(1.0)
    }

    func enableTrianglesElementBuffer (_ meshIndex: Int) {
        glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), privD!.facesVbo[meshIndex])
    }

    func renderPartialMesh (_ meshIndex: Int) {
        //nothing uploaded. return test
        if privD!.numTriangleIndices[meshIndex] <= 0 {
            return
        }

        switch privD!.currentRenderingMode {

        case RenderingMode.xRay:

            enableLinesElementBuffer(meshIndex)
            enableVertexBuffer(meshIndex)
            enableNormalBuffer(meshIndex)
            glDrawElements( GLenum(GL_LINES), GLsizei(privD!.numLinesIndices[meshIndex]), GLenum(GL_UNSIGNED_INT), nil)
            disableNormalBuffer(meshIndex)
            disableVertexBuffer(meshIndex)

        case RenderingMode.lightedGray:

            enableTrianglesElementBuffer(meshIndex)
            enableVertexBuffer(meshIndex)
            enableNormalBuffer(meshIndex)
            glDrawElements( GLenum(GL_TRIANGLES), GLsizei(privD!.numTriangleIndices[meshIndex]), GLenum(GL_UNSIGNED_INT), nil)
            disableNormalBuffer(meshIndex)
            disableVertexBuffer(meshIndex)

        case RenderingMode.perVertexColor:

            enableTrianglesElementBuffer(meshIndex)
            enableVertexBuffer(meshIndex)
            enableNormalBuffer(meshIndex)
            enableVertexColorBuffer(meshIndex)
            glDrawElements( GLenum(GL_TRIANGLES), GLsizei(privD!.numTriangleIndices[meshIndex]), GLenum(GL_UNSIGNED_INT), nil)
            disableVertexColorBuffer(meshIndex)
            disableNormalBuffer(meshIndex)
            disableVertexBuffer(meshIndex)

        case RenderingMode.textured:

            enableTrianglesElementBuffer(meshIndex)
            enableVertexBuffer(meshIndex)
            enableVertexTexcoordsBuffer(meshIndex)
            glDrawElements( GLenum(GL_TRIANGLES), GLsizei(privD!.numTriangleIndices[meshIndex]), GLenum(GL_UNSIGNED_INT), nil)
            disableVertexTexcoordBuffer(meshIndex)
            disableVertexBuffer(meshIndex)
        }

        glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), 0)
    }

 func render(_ projectionMatrix: UnsafePointer<GLfloat>, modelViewMatrix: UnsafePointer<GLfloat>) {

        if privD!.currentRenderingMode == RenderingMode.perVertexColor && !privD!.hasPerVertexColor && privD!.hasTexture && privD!.hasPerVertexUV {

            NSLog("Warning: The mesh has no per-vertex colors, but a texture, switching the rendering mode to Textured")
            privD!.currentRenderingMode = RenderingMode.textured
        } else if privD!.currentRenderingMode == RenderingMode.textured && (!privD!.hasTexture || !privD!.hasPerVertexUV) && privD!.hasPerVertexColor {
            NSLog("Warning: The mesh has no texture, but per-vertex colors, switching the rendering mode to PerVertexColor")
            privD!.currentRenderingMode = RenderingMode.perVertexColor
        }

        switch privD!.currentRenderingMode {

        case RenderingMode.xRay:
            privD!.xRayShader!.enable()
            privD!.xRayShader!.prepareRendering(projectionMatrix, modelView: modelViewMatrix)

        case RenderingMode.lightedGray:
            privD!.lightedGrayShader!.enable()
            privD!.lightedGrayShader!.prepareRendering(projectionMatrix, modelView: modelViewMatrix)

        case RenderingMode.perVertexColor:
            if !privD!.hasPerVertexColor {
                NSLog("Warning: the mesh has no colors, skipping rendering.")
                return
            }

            privD!.perVertexColorShader!.enable()
            privD!.perVertexColorShader!.prepareRendering(projectionMatrix, modelView: modelViewMatrix)

        case RenderingMode.textured:
            if !privD!.hasTexture || privD!.lumaTexture == nil || privD!.chromaTexture == nil {
                NSLog("Warning: null textures, skipping rendering.")
                return
            }

            glActiveTexture(privD!.textureUnit)
            glBindTexture(CVOpenGLESTextureGetTarget(privD!.lumaTexture!), CVOpenGLESTextureGetName(privD!.lumaTexture!))

            glActiveTexture(privD!.textureUnit + 1)
            glBindTexture(CVOpenGLESTextureGetTarget(privD!.chromaTexture!), CVOpenGLESTextureGetName(privD!.chromaTexture!))

            privD!.yCbCrTextureShader!.enable()
            privD!.yCbCrTextureShader!.prepareRendering(projectionMatrix, modelView: modelViewMatrix, textureUnit: GLint(privD!.textureUnit))
        }

        // Keep previous GL_DEPTH_TEST state
        let wasDepthTestEnabled: GLboolean = glIsEnabled( GLenum(GL_DEPTH_TEST))
        glEnable( GLenum(GL_DEPTH_TEST))

        for iii in 0..<privD!.numUploadedMeshes {
            renderPartialMesh(iii)
        }

        if wasDepthTestEnabled == GLboolean(GL_FALSE) {
            glDisable( GLenum(GL_DEPTH_TEST))
        }
    }
}
