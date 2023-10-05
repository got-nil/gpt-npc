local default_system_prompt = MODULE:Config():Get("default_system_prompt", false)

return {
    name = "gpt",
    validate = function(gpt_params)
        if not gpt_params.IsInstanceOf then return false end
        return gpt_params:IsInstanceOf(GNIL.GPT.Classes.GPTParameters)
    end,
    request = function(_, gpt_params)
        
        local tbl = gpt_params:ToTable()
        if #tbl.messages == 0 then
            return false, "No messages provided"
        end

        -- Set default system prompt from config if there is
        -- one and there is no system_prompt set on the params.
        if not tbl.system_prompt and default_system_prompt then
            tbl.system_prompt = default_system_prompt
        end

        -- Always return a set structure just incase.
        return true, {
            ["messages"] = tbl.messages,
            ["system_prompt"] = tbl.system_prompt,
            ["functions"] = tbl.functions
        }
    end,
    response = function(task, data)
        
        -- There is no additional processing required.
        return true, {
            data["message"],
            data
        }
    end
}