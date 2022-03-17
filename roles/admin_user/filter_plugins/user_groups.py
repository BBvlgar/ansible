#!/usr/bin/env python3

class FilterModule( object ):

    def filters( self ):
        return {
            'removableGroupsOfUsers': self.removableGroupsOfUsers,
        }

    def removableGroupsOfUsers( self, userDict, currentGroups ):
        """
        function to gather all remote asigned groups of users to be
        checked against the allowed groups
        """

        # import sys, json

        removable = {}
        for uname, groupCSV in userDict.items():
            if len( currentGroups[ uname ] ) > 0:
                allowed = groupCSV.split( ',' )
                rm      = list(
                    set( currentGroups[ uname ][ "all" ] ) -
                    set( allowed ) -
                    set( currentGroups[ uname ][ "effective" ] )
                )
                if len( rm ) > 0:
                    removable[ uname ] = rm

        return removable
