WITH latest_year AS (
    SELECT max(d_year) AS yr FROM date_dim
),
sales_raw AS (
    SELECT 
        ss.ss_store_sk AS entity_sk,
        st.s_store_name AS entity_name,
        'store' AS channel,
        i.i_category AS category,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_net_profit AS profit,
        ss.ss_ext_discount_amt AS discount_amt,
        1 AS txn
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = (SELECT yr FROM latest_year)
    UNION ALL
    SELECT 
        ws.ws_web_site_sk AS entity_sk,
        wss.web_name AS entity_name,
        'web' AS channel,
        i.i_category,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        1
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wss ON ws.ws_web_site_sk = wss.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = (SELECT yr FROM latest_year)
    UNION ALL
    SELECT 
        cs.cs_call_center_sk AS entity_sk,
        cc.cc_name AS entity_name,
        'catalog' AS channel,
        i.i_category,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        1
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = (SELECT yr FROM latest_year)
),
sales_agg AS (
    SELECT 
        entity_sk,
        entity_name,
        channel,
        category,
        SUM(net_paid) AS total_net_paid,
        SUM(profit) AS total_profit,
        SUM(discount_amt) AS total_discount,
        COUNT(*) AS total_txns
    FROM sales_raw
    GROUP BY entity_sk, entity_name, channel, category
),
returns_agg AS (
    SELECT 
        d.d_year,
        SUM(CASE WHEN src = 'store' THEN loss END) AS store_loss,
        SUM(CASE WHEN src = 'web' THEN loss END) AS web_loss,
        SUM(CASE WHEN src = 'catalog' THEN loss END) AS catalog_loss
    FROM (
        SELECT sr_returned_date_sk AS return_date_sk, sr_net_loss AS loss, 'store' AS src FROM store_returns
        UNION ALL
        SELECT wr_returned_date_sk, wr_net_loss, 'web' FROM web_returns
        UNION ALL
        SELECT cr_returned_date_sk, cr_net_loss, 'catalog' FROM catalog_returns
    ) r
    JOIN date_dim d ON r.return_date_sk = d.d_date_sk
    WHERE d.d_year = (SELECT yr FROM latest_year)
    GROUP BY d.d_year
),
total_loss AS (
    SELECT (store_loss + web_loss + catalog_loss) AS overall_loss FROM returns_agg
),
ranked AS (
    SELECT 
        sa.entity_sk,
        sa.entity_name,
        sa.channel,
        sa.category,
        sa.total_net_paid,
        sa.total_profit,
        sa.total_discount,
        sa.total_txns,
        (sa.total_profit / nullif(sa.total_net_paid, 0)) AS profit_margin,
        (sa.total_discount / nullif(sa.total_txns, 0)) AS avg_discount_per_txn,
        rl.overall_loss,
        RANK() OVER (PARTITION BY sa.channel ORDER BY sa.total_profit DESC) AS channel_profit_rank,
        RANK() OVER (ORDER BY sa.total_profit DESC) AS overall_profit_rank
    FROM sales_agg sa
    CROSS JOIN total_loss rl
)
SELECT 
    entity_sk,
    entity_name,
    channel,
    category,
    total_net_paid,
    total_profit,
    total_discount,
    total_txns,
    profit_margin,
    avg_discount_per_txn,
    overall_loss,
    channel_profit_rank,
    overall_profit_rank
FROM ranked
WHERE overall_profit_rank <= 10
ORDER BY overall_profit_rank
