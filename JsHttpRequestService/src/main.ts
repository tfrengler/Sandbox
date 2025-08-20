class HttpRequestService
{
    private _xmlHttpRequest: XMLHttpRequest
    private _destination: string
    private _body: any
    private _timeout: number
    private _urlParams: URLSearchParams
    private _headers: Array<IHeader>
    private _method: HttpRequestMethod
    private _progressCallback: (this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any
    private _id: string

    static _defaultHeaders: Array<IHeader>
    static _defaultTimeout: number

    constructor(method: HttpRequestMethod, destination: string) {
        this._xmlHttpRequest = new XMLHttpRequest();
        this._destination = destination;
        this._body = null;
        this._timeout = HttpRequestService._defaultTimeout;
        this._urlParams = new URLSearchParams();
        this._headers = [];
        this._method = method;
        this._progressCallback = function () {};
        this._id = Date.now().toString(36) + Math.random().toString(36).substring(2, 12).padStart(12, '0');

        console.debug(`New ${this._method}-request created with id ${this._id} for URI: ${this._destination}`);

        return this;
    }

    _onend(self: HttpRequestService) {
        console.timeEnd(`Response received (${self._id})`);
        console.debug(`Request to ${self._destination} ended without errors`);
    }

    _onabort(self: HttpRequestService) {
        console.error(`Request to ${self._destination} was aborted`);
    }

    _ontimeout(self: HttpRequestService) {
        console.error(`Request to ${self._destination} timed out (${self._timeout} ms)`);
    }

    _onerror(self: HttpRequestService) {
        console.error(`Request to ${self._destination} thrown an error`);
    }

    static setDefaultHeaders(headers: Array<IHeader>) {
        this._defaultHeaders = headers;
    }

    static GET(destination: string): HttpRequestService {
        return new HttpRequestService(HttpRequestMethod.GET, destination);
    }

    static POST(destination: string): HttpRequestService {
        return new HttpRequestService(HttpRequestMethod.POST, destination);
    }

    static PUT(destination: string): HttpRequestService {
        return new HttpRequestService(HttpRequestMethod.PUT, destination);
    }

    static DELETE(destination: string): HttpRequestService {
        return new HttpRequestService(HttpRequestMethod.DELETE, destination);
    }

    static HEAD(destination: string): HttpRequestService {
        return new HttpRequestService(HttpRequestMethod.HEAD, destination);
    }

    withTimeout(timeoutInMS: number): HttpRequestService {
        this._timeout = timeoutInMS < 5000 ? 5000 : timeoutInMS;
        return this;
    }

    withUrlParam(name: string, value: string): HttpRequestService {
        this._urlParams.append(name, value);
        return this;
    }

    withHeader(name: string, value: string): HttpRequestService {
        this._xmlHttpRequest.setRequestHeader(name, value);
        return this;
    }

    withStringBody(body: string): HttpRequestService {
        this._body = body;
        this._headers.push({Name: "Content-Type", Value: "plain/text"});
        return this;
    }

    withJSONBody(body: any): HttpRequestService {
        this._body = JSON.stringify(body);
        this._headers.push({Name: "Content-Type", Value: "application/json"});
        return this;
    }

    withArrayBufferBody(body: ArrayBuffer): HttpRequestService {
        this._body = body;
        this._headers.push({Name: "Content-Type", Value: "application/octet-stream"});
        return this;
    }

    withFormDataBody(body: FormData): HttpRequestService {
        this._body = body;
        return this;
    }

    onProgress(handler: (this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any): HttpRequestService {
        this._progressCallback = handler;
        return this;
    }

    async send<T>(): Promise<T> {
        console.debug(`Sending request (${this._id})`);
        console.time(`Response received (${this._id})`);

        return new Promise((resolve: Function, reject: Function) => {
            try {
                let destination = this._destination + '?' + this._urlParams.toString();
                this._xmlHttpRequest.timeout = this._timeout;
                this._xmlHttpRequest.open(this._method, destination, true);

                if (this._progressCallback) {
                    this._xmlHttpRequest.onprogress = this._progressCallback;
                }

                for (const currentHeader of this._headers) {
                    this._xmlHttpRequest.setRequestHeader(currentHeader.Name, currentHeader.Value);
                }

                this._xmlHttpRequest.onload = () => {
                    this._onend(this);
                    resolve(this._xmlHttpRequest.response);
                };

                this._xmlHttpRequest.onerror = () => {
                    this._onerror(this);
                    reject(this._xmlHttpRequest);
                }

                this._xmlHttpRequest.ontimeout = () => {
                    this._ontimeout(this);
                    reject(this._xmlHttpRequest);
                }

                this._xmlHttpRequest.onabort = () => {
                    this._ontimeout(this);
                    reject(this._xmlHttpRequest);
                }

                this._xmlHttpRequest.send(this._body);
            }
            catch(error: any) {
                reject(error);
            }
        });
    }
}

interface IHeader {
    Name: string,
    Value: string
}

enum HttpRequestMethod
{
    GET = "GET",
    POST = "POST",
    HEAD = "HEAD",
    DELETE = "DELETE",
    PUT = "PUT"
}

export { HttpRequestService }