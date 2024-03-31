#include <maya/MFnPlugin.h>
#include <maya/MGlobal.h>
#include <maya/MPxCommand.h>

class HelloWorld : public MPxCommand
{
  public:
    virtual MStatus doIt( const MArgList &args ) override;
    static void *creator();
};

MStatus HelloWorld::doIt( const MArgList &args )
{
    MGlobal::displayInfo( "Hello World" );
    return MStatus::kSuccess;
}

void *HelloWorld::creator()
{
    return new HelloWorld;
}

MStatus initializePlugin( MObject plugin )
{
    MFnPlugin fnPlugin( plugin, MAYA_PLUGIN_VENDOR, MAYA_PLUGIN_VERSION, "Any" );

    fnPlugin.registerCommand( "helloWorld", HelloWorld::creator );

    return MStatus::kSuccess;
}

MStatus uninitializePlugin( MObject plugin )
{
    MFnPlugin fnPlugin( plugin );

    fnPlugin.deregisterCommand( "helloWorld" );

    return MStatus::kSuccess;
}
