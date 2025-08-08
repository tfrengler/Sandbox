/**
 * @hint Candidates API controller
 * @Trail
 * @TrailAPI
 * @TrailRoute api/candidate
 */
component displayname="Controller" modifier="final" output="false" accessors="false" persistent="true" {

    /**
     * @TrailEndpoint /
     * @TrailMethod POST
     */
    public string function Search(required numeric candidateId) output = false {
        return serializeJSON({
            candidateId: arguments.candidateId
        });
    }

    /**
     * @TrailEndpoint {candidateId}
     * @TrailMethod GET
     */
    public string function Get(required numeric candidateId) output = false {
        cfcontent(type="application/json");
        return serializeJSON({
            candidateId: arguments.candidateId
        });
    }

    /**
     * @TrailEndpoint {candidateId}
     * @TrailMethod PUT
     */
    public string function Update(required numeric candidateId) output = false {
        cfcontent(type="application/json");
        return serializeJSON({
            candidateId: arguments.candidateId
        });
    }

    /**
     * @TrailEndpoint {candidateId}/application/{applicationId}
     */
    public string function GetApplication(required numeric candidateId, required numeric applicationId) output = false {
        cfcontent(type="application/json");
        return serializeJSON({
            candidateId: arguments.candidateId,
            applicationId: arguments.applicationId,
        });
    }
}