
set( SimpleITKIOSource
  sitkImageFileReader.cxx
  sitkImageFileWriter.cxx
  sitkImageReaderBase.cxx
  sitkImageSeriesReader.cxx
  sitkImageSeriesWriter.cxx
  sitkImportImageFilter.cxx
  sitkShow.cxx
  )

include_directories( ${CMAKE_CURRENT_SOURCE_DIR} )

set(REQUIRED_ITK_MODULES  ITKCommon ITKLabelMap ITKImageCompose
  ITKImageIntensity ITKIOImageBase ITKIOTransformBase ITKIOGDCM )
foreach( mod IN LISTS ITK_MODULES_ENABLED)
  if( ${mod} MATCHES "IO")
    list(APPEND REQUIRED_ITK_MODULES ${mod})
  endif()
endforeach()

find_package(ITK COMPONENTS REQUIRED)
include(${ITK_USE_FILE})

add_library ( SimpleITKIO ${SimpleITKIOSource} )
target_link_libraries ( SimpleITKIO ${ITK_LIBRARIES} SimpleITKCommon )
set_target_properties( SimpleITKIO PROPERTIES SKIP_BUILD_RPATH TRUE )

sitk_install_exported_target( SimpleITKIO )

# Add custom command that will delete java files which need to be rebuilt when changes
# are made to IO
if( WRAP_JAVA )
  add_custom_command(
    TARGET SimpleITKIO
    POST_BUILD
    COMMENT "Cleaning java build..."
    COMMAND ${CMAKE_COMMAND} -E remove -f ${SimpleITK_BINARY_DIR}/Wrapping/org/itk/simple/*.java
    COMMAND ${CMAKE_COMMAND} -E remove -f ${SimpleITK_BINARY_DIR}/Wrapping/build/org/itk/simple/*.class
  )
endif()
