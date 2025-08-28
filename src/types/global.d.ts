/* eslint-disable @typescript-eslint/no-explicit-any */
// 声明模块类型以解决 TypeScript 找不到模块的问题
declare module '@dnd-kit/core' {
  export * from '@dnd-kit/core/dist/index';
}

declare module '@dnd-kit/modifiers' {
  export * from '@dnd-kit/modifiers/dist/index';
}

declare module '@dnd-kit/sortable' {
  export * from '@dnd-kit/sortable/dist/index';
}

declare module '@dnd-kit/utilities' {
  export * from '@dnd-kit/utilities/dist/index';
}

declare module 'lucide-react' {
  export * from 'lucide-react/dist/lucide-react';
}

declare module 'sweetalert2' {
  const Swal: any;
  export default Swal;
}

declare module 'artplayer' {
  interface ArtplayerOption {
    container: string | HTMLElement;
    url?: string;
    poster?: string;
    title?: string;
    theme?: string;
    volume?: number;
    isLive?: boolean;
    muted?: boolean;
    autoplay?: boolean;
    pip?: boolean;
    autoSize?: boolean;
    autoMini?: boolean;
    screenshot?: boolean;
    setting?: boolean;
    loop?: boolean;
    flip?: boolean;
    playbackRate?: boolean;
    aspectRatio?: boolean;
    fullscreen?: boolean;
    fullscreenWeb?: boolean;
    subtitleOffset?: boolean;
    miniProgressBar?: boolean;
    mutex?: boolean;
    backdrop?: boolean;
    playsInline?: boolean;
    autoPlayback?: boolean;
    airplay?: boolean;
    layers?: any[];
    contextmenu?: any[];
    controls?: any[];
    quality?: any[];
    highlight?: any[];
    plugins?: any[];
    thumbnails?: any;
    subtitle?: any;
    moreVideoAttr?: any;
    icons?: any;
    customType?: any;
    [key: string]: any;
  }

  class Artplayer {
    static PLAYBACK_RATE: number[];
    static USE_RAF: boolean;
    
    constructor(option: ArtplayerOption);
    destroy(): void;
    play(): void;
    pause(): void;
    toggle(): void;
    seek: number;
    forward: number;
    backward: number;
    volume: number;
    url: string;
    switch: string;
    switchUrl(url: string): void;
    switchQuality(url: string): void;
    muted: boolean;
    currentTime: number;
    duration: number;
    video: HTMLVideoElement;
    playing: boolean;
    playbackRate: number;
    aspectRatio: string;
    screenshot(): string;
    fullscreen: boolean;
    fullscreenWeb: boolean;
    pip: boolean;
    loaded: number;
    played: number;
    proxy: any;
    query: any;
    template: any;
    events: any;
    option: ArtplayerOption;
    player: any;
    layers: any;
    contextmenu: any;
    controls: any;
    setting: any;
    storage: any;
    plugins: any;
    notice: any;
    on: any;
    off: any;
    [key: string]: any;
  }

  export = Artplayer;
}

declare module 'hls.js' {
  export interface HlsConfig {
    [key: string]: any;
  }

  export interface LoaderContext {
    [key: string]: any;
  }

  export interface LoaderConfig {
    [key: string]: any;
  }

  export interface LoaderResponse {
    [key: string]: any;
  }

  export interface LoaderStats {
    [key: string]: any;
  }

  export interface LoaderCallbacks {
    [key: string]: any;
  }

  export interface ErrorData {
    [key: string]: any;
  }

  export interface FragLoadedData {
    [key: string]: any;
  }

  export default class Hls {
    static isSupported(): boolean;
    static DefaultConfig: any;
    static ErrorTypes: any;
    static Events: any;

    constructor(config?: any);
    destroy(): void;
    attachMedia(media: HTMLMediaElement): void;
    detachMedia(): void;
    loadSource(url: string): void;
    startLoad(startPosition?: number): void;
    stopLoad(): void;
    swapAudioCodec(): void;
    recoverMediaError(): void;
    on: any;
    off: any;
    trigger: any;
    listenerCount: any;
    [key: string]: any;
  }
}

declare module 'redis' {
  export interface RedisClientOptions {
    [key: string]: any;
  }

  export interface RedisClientType {
    connect(): Promise<void>;
    disconnect(): Promise<void>;
    isOpen: boolean;
    isReady: boolean;
    get(key: string): Promise<string | null>;
    set(key: string, value: string, options?: any): Promise<any>;
    del(...keys: string[]): Promise<number>;
    exists(...keys: string[]): Promise<number>;
    keys(pattern: string): Promise<string[]>;
    mget(...keys: string[]): Promise<(string | null)[]>;
    mGet(keys: string[]): Promise<(string | null)[]>;
    expire(key: string, seconds: number): Promise<boolean>;
    ttl(key: string): Promise<number>;
    scan(cursor: number, options?: any): Promise<{ cursor: number; keys: string[] }>;
    lRange(key: string, start: number, stop: number): Promise<string[]>;
    lRem(key: string, count: number, element: string): Promise<number>;
    lPush(key: string, ...elements: string[]): Promise<number>;
    lTrim(key: string, start: number, stop: number): Promise<string>;
    on(event: string, listener: (...args: any[]) => void): this;
    off(event: string, listener: (...args: any[]) => void): this;
    [key: string]: any;
  }

  export function createClient(options?: RedisClientOptions): RedisClientType;
}

declare module '@upstash/redis' {
  export interface RedisConfigNodejs {
    [key: string]: any;
  }

  export class Redis {
    constructor(config: RedisConfigNodejs);
    get(key: string): Promise<string | null>;
    set(key: string, value: any, options?: any): Promise<any>;
    del(...keys: string[]): Promise<number>;
    exists(...keys: string[]): Promise<number>;
    keys(pattern: string): Promise<string[]>;
    mget(keys: string[]): Promise<(string | null)[]>;
    expire(key: string, seconds: number): Promise<boolean>;
    ttl(key: string): Promise<number>;
    scan(cursor: number, options?: any): Promise<{ cursor: number; keys: string[] }>;
    lrange(key: string, start: number, stop: number): Promise<string[]>;
    lrem(key: string, count: number, element: string): Promise<number>;
    lpush(key: string, ...elements: string[]): Promise<number>;
    ltrim(key: string, start: number, stop: number): Promise<string>;
    [key: string]: any;
  }
}