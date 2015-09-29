import std.exception, std.json, std.net.curl, std.process, std.regex, std.stdio;
import std.algorithm.searching : endsWith;
import std.string : chomp;
import std.range : chain;

void graph(string title)
{
    writeln("multigraph rabbitmq_", title);
    writeln("graph_title RabbitMQ ", title);
    writeln("graph_args --base 1000 -l 0");
    writeln("graph_category RabbitMQ");
}

enum QUEUE_STATS = ["messages", "messages_ready", "messages_unacknowledged",
        "messages_persistent"];

string escape(string s)
{
    import std.string : tr;

    return s.tr("/.=-", "____");
}

void config(string api)
{
    auto data = get(api ~ "overview").parseJSON;
    foreach (stat; ["object_totals", "queue_totals", "message_stats"])
    {
        graph(stat);
        foreach (k, v; data[stat].object)
        {
            if (k.endsWith("_details"))
                continue;
            writeln(k, ".label ", k);
            writeln(k, ".min 0");
            if (stat == "message_stats")
                writeln(k, ".type COUNTER");
        }
    }

    data = get(api ~ "queues").parseJSON;
    if (data.array.length)
    {
        graph("queues");
        foreach (q; data.array)
        {
            auto vhost = q["vhost"].str.chomp("/");
            auto pfx = chain(vhost, vhost.length ? "_" : "");
            auto qname = q["name"].str.escape;
            foreach (stat; QUEUE_STATS)
            {
                if (stat !in q)
                    continue;
                writeln(pfx, qname, "_", stat, ".label ", vhost, "_", qname, "_", stat);
                writeln(pfx, qname, "_", stat, ".min 0");
                writeln(pfx, qname, "_", stat, ".vlabel msgs");
            }
        }
    }

    data = get(api ~ "exchanges").parseJSON;
    graph("exchanges");
    foreach (x; data.array)
    {
        auto vhost = x["vhost"].str.chomp("/");
        auto pfx = chain(vhost, vhost.length ? "_" : "");
        auto xname = x["name"].str.escape;
        auto stats = x.object.get("message_stats", JSONValue());
        if (!stats.isNull && "publish_in" in stats)
        {
            writeln(pfx, xname, "_publish_in.label ", vhost, "_", xname, "_publish_in");
            writeln(pfx, xname, "_publish_in.type COUNTER");
            writeln(pfx, xname, "_publish_in.vlabel msgs / ${graph_period}");
        }
    }
}

void values(string api)
{
    auto data = get(api ~ "overview").parseJSON;
    foreach (stat; ["object_totals", "queue_totals", "message_stats"])
    {
        writeln("multigraph rabbitmq_", stat);
        foreach (k, v; data[stat].object)
        {
            if (!k.endsWith("_details"))
                writeln(k, ".value ", v);
        }
    }

    data = get(api ~ "queues").parseJSON;
    if (data.array.length)
    {
        writeln("multigraph rabbitmq_queues");
        foreach (q; data.array)
        {
            auto vhost = q["vhost"].str.chomp("/");
            auto pfx = chain(vhost, vhost.length ? "_" : "");
            auto qname = q["name"].str.escape;
            foreach (stat; QUEUE_STATS)
            {
                if (auto pval = stat in q)
                    writeln(pfx, qname, "_", stat, ".value ", *pval);
            }
        }
    }

    data = get(api ~ "exchanges").parseJSON;
    writeln("multigraph rabbitmq_exchanges");
    foreach (x; data.array)
    {
        auto vhost = x["vhost"].str.chomp("/");
        auto pfx = chain(vhost, vhost.length ? "_" : "");
        auto xname = x["name"].str.escape;
        auto stats = x.object.get("message_stats", JSONValue());
        const(JSONValue)* pval;
        if (!stats.isNull && (pval = "publish_in" in stats) !is null)
            writeln(pfx, xname, "_publish_in.value ", *pval);
    }
}

int main(string[] args)
{
    auto api = enforce(environment.get("API_URL", null),
        "Please set 'env.API_URL' in plugin-conf.d.");
    if (!api.endsWith("/"))
        api ~= "/";

    if (args.length > 1 && args[1] == "config")
        config(api);
    else
        values(api);
    return 0;
}
