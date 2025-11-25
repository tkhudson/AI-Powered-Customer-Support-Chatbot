import streamlit as st
from langchain_openai import ChatOpenAI
from langchain_anthropic import ChatAnthropic
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, AIMessage

st.set_page_config(page_title="Hudson – AI Support Bot Demo", page_icon="robot")

st.title("Hudson – AI Customer Support Bot")
st.markdown("Live demo • Works with **Grok • Claude • GPT • Gemini • Ollama** • Your key, your model")

model_option = st.selectbox(
    "Choose your AI model",
    ["xAI Grok (grok-4-1-fast-reasoning)", "OpenAI (GPT-4o / GPT-4o-mini)", "Anthropic (Claude 3.5 Sonnet)", "Google Gemini (1.5 Pro)", "Local (Ollama / LM Studio)"]
)

api_key = st.text_input(
    f"Enter your {model_option.split()[0]} API key",
    type="password",
    help="Your key is used only in this session • Never stored • Get free credits below",
    placeholder="Paste key here..."
)

if not api_key:
    st.info("Paste your key above to activate the bot")
    st.markdown("""
    ### Want your own fully custom version?
    → Message me on Upwork:  
    [https://www.upwork.com/freelancers/~0185d8801c4b1f9561](https://www.upwork.com/freelancers/~0185d8801c4b1f9561)  
    (or search **Tyler Hudson**)
    """)
    st.stop()

# Model routing
if "Grok" in model_option:
    llm = ChatOpenAI(model="grok-4-1-fast-reasoning", api_key=api_key, base_url="https://api.x.ai/v1", temperature=0.4)
elif "OpenAI" in model_option:
    llm = ChatOpenAI(model="gpt-4o-mini", api_key=api_key, temperature=0.4)
elif "Claude" in model_option:
    llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", api_key=api_key, temperature=0.4)
elif "Gemini" in model_option:
    llm = ChatGoogleGenerativeAI(model="gemini-1.5-pro", google_api_key=api_key, temperature=0.4)
elif "Local" in model_option:
    llm = ChatOpenAI(base_url="http://localhost:11434/v1", api_key="ollama", model="llama3.2", temperature=0.4)

if "messages" not in st.session_state:
    st.session_state.messages = [AIMessage(content="Hey! I'm your AI support assistant from Hudson IT Consulting. Ask me anything about cybersecurity, WordPress, automation, servers, or custom AI agents.")]

for msg in st.session_state.messages:
    if isinstance(msg, HumanMessage):
        st.chat_message("human").write(msg.content)
    else:
        st.chat_message("ai").write(msg.content)

if prompt := st.chat_input("What do you need help with?"):
    st.session_state.messages.append(HumanMessage(content=prompt))
    st.chat_message("human").write(prompt)

    with st.chat_message("ai"):
        with st.spinner("Thinking..."):
            response = llm.invoke(st.session_state.messages)
        st.write(response.content)
        st.session_state.messages.append(AIMessage(content=response.content))

st.markdown("---")
st.success("Love the bot? Get your own unlimited version — any model, any features")
st.markdown("""
**Contact me directly on Upwork:**  
[https://www.upwork.com/freelancers/~0185d8801c4b1f9561](https://www.upwork.com/freelancers/~0185d8801c4b1f9561)  
Fast delivery • Fixed or hourly • 100% satisfaction
""")
st.caption("Built by Tyler Hudson – AI Agents & Automation Expert")