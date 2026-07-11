import json
import csv
import requests
import time

url= 'https://stream.wikimedia.org/v2/stream/recentchange'
headers= {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

print("STARTING MASTER GLOBAL WIKI INGESTION & ANALYTICS")

#1. Initalize csv file
with open('live_wiki_data.csv', mode= "w", newline='', encoding= "utf-8") as file:
    writer= csv.writer(file)
    writer.writerow(['Timestamp','PageTitle', 'Is_bot', 'Wiki_Language'])
print("Live CSV storage initialized")

#Tracking running analysis statistics 
total_edits_processed= 0
bot_count= 0
human_count= 0

while True:
    print("\nAttempting to connect to global streaming pipe...")
    try:
        response= requests.get(url, headers=headers, stream= True, timeout= 60)

        if response.status_code == 200:
            print("Connected successfully! Analysing stream in real-time...\n")

            for line in response.iter_lines():
                if line:
                    decoded_line= line.decode('utf-8')

                    if decoded_line.startswith('data:'):
                        try:
                            raw_json= decoded_line[5:].strip()
                            change= json.loads(raw_json)

                            #filtering for text edits only
                            if change.get('type') == 'edit':
                                page_title= change.get('title', 'Unknown')
                                timestamp= change.get('timestamp', '')
                                is_bot= change.get('bot', False)
                                server_name= change.get('server_name', '')

                                #Geographic and bot metadata extraction
                                wiki_language= server_name.split('.')[0] if server_name else 'unknown'

                                if isinstance(timestamp, (int, float)):
                                    clean_timestamp= time.strftime('%Y-%m-%d %H:%M:%S', time.gmtime(timestamp))
                                else:
                                    clean_timestamp= str(timestamp).replace('Z', '')[:19]

                                #Running traffic metric calculations
                                total_edits_processed +=1
                                if is_bot:
                                    bot_count +=1
                                else:
                                    human_count +=1

                                bot_percentage= (bot_count / total_edits_processed) *100

                                #Storage 
                                with open('live_wiki_data.csv', mode= 'a', newline= '', encoding= 'utf-8') as file:
                                    writer= csv.writer(file)
                                    writer.writerow([clean_timestamp, page_title, is_bot, wiki_language])

                                print(f"[{wiki_language.upper()}] {'(BOT)' if is_bot else 'Human'} -> {page_title[:40]}", flush= True)
                                print(f"Running Stats | Total Edits: {total_edits_processed} | Bots: {bot_count} ({bot_percentage: .1f}%) | Humans: {human_count}", flush= True)
                                print("-" *70, flush= True)
                                
                        except (json.JSONDecodeError, ValueError, KeyError, IndexError):
                            continue
        else:
            print(f"Server refused connection. Status code: {response.status_code}")
        
    except KeyboardInterrupt:
        print("\n Harvester stopped manually by user.")
        break

    except Exception as e:
        print(f"\n Stream disconnected unexpectedly ({e}). Reconnecting in 5 seconds..")
        time.sleep(5)