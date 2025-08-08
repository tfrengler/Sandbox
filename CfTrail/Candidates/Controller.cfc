/**
 * @hint Candidates-controller
 * @Trail
 * @TrailView
 * @TrailRoute view/candidate
 */
component displayname="Controller" modifier="final" output="false" accessors="false" persistent="true" {

    /**
     * @TrailEndpoint {candidateId}
     */
    public string function GetCandidateWithId(required numeric candidateId) output = false {
        var returnData = "";

        cfsavecontent(variable="returnData") {
            cfmodule(template="candidate.cfm", attributecollection=arguments);
        }

        return returnData;
    }

    /**
     * @TrailEndpoint debug1/
     */
    public string function Debug1() output = false {
        return "";
    }

    /**
     * @TrailEndpoint /debug2
     */
    public string function Debug2() output = false {
        return "";
    }

    /**
     * @TrailEndpoint {candidateId}
     */
    public string function GetCandidateWithId2(required numeric candidateId) output = false {
        return "";
    }

    /**
     * @TrailEndpoint {candidateId}/application/{applicationId}
     */
    public string function GetApplicationWithId(required numeric candidateId, required numeric applicationId) output = false {
        var returnData = "";

        cfsavecontent(variable="returnData") {
            cfmodule(template="application.cfm", attributecollection=arguments);
        }

        return returnData;
    }
}