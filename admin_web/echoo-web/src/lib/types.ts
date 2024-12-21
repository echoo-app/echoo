export type OpenRouterModel = {
    id: string;
    name: string;
    description: string;
    pricing: {
        prompt: string;
        completion: string;
        image?: string;
        request: string;
    };
    context_length: number;
    architecture: {
        modality: string;
        tokenizer: string;
        instruct_type: string | null;
    };
};

export type User = {
    id: number;
    username: string;
    api_calls: number;
    created_at: string;
    is_vip: boolean;
};

export type VipCode = {
    id: number;
    code: string;
    enabled: boolean;
    used: boolean;
    used_by: number | null;
    used_at: string | null;
    payment_url: string;
    payment_url_expires_at: string | null;
    created_at: string;
};

export type GenerateVipCodeResponse = {
    code: string;
    payment_url: string;
};

export type UpdateVipCodeRequest = {
    enabled?: boolean;
    payment_url?: string;
};
