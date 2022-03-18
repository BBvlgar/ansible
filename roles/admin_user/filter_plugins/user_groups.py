#!/usr/bin/env python3

class FilterModule( object ):

    def filters( self ):
        return {
            'removableGroupsOfUsers': self.removableGroupsOfUsers,
            'prepareExistingGroups': self.prepareExistingGroups,
        }

    def removableGroupsOfUsers( self, userDict, currentGroups ):
        """
        function to gather all remote asigned groups of users to be
        checked against the allowed groups
        """

        # import sys, json

        removable = {}
        for uname, groupCSV in userDict.items():
            if uname in currentGroups and len( currentGroups[ uname ] ) > 0:
                allowed = groupCSV.split( ',' )
                rm      = list(
                    set( currentGroups[ uname ][ "all" ] ) -
                    set( allowed ) -
                    set( [ currentGroups[ uname ][ "effective" ] ] )
                )
                if len( rm ) > 0:
                    removable[ uname ] = rm

        return removable

    def prepareExistingGroups( self, username, stdout, stderr ):
        """
        function to only merge existing groups if user exists
        """
        import json
        groups = {}
        if "no such user" not in stderr:
            groups = {
                username: json.loads( stdout )
            }
        return groups
