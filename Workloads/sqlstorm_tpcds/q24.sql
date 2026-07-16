WITH date_filtered AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2002
), 
store_sales_agg AS (
    SELECT 
        ss.ss_item_sk AS item_sk,
        ss.ss_store_sk AS channel_id,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity,
        COUNT(*) AS transactions,
        'store' AS channel
    FROM store_sales ss
    JOIN date_filtered df ON ss.ss_sold_date_sk = df.d_date_sk
    GROUP BY ss.ss_item_sk, ss.ss_store_sk
),
web_sales_agg AS (
    SELECT 
        ws.ws_item_sk AS item_sk,
        ws.ws_web_site_sk AS channel_id,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity,
        COUNT(*) AS transactions,
        'web' AS channel
    FROM web_sales ws
    JOIN date_filtered df ON ws.ws_sold_date_sk = df.d_date_sk
    GROUP BY ws.ws_item_sk, ws.ws_web_site_sk
),
catalog_sales_agg AS (
    SELECT 
        cs.cs_item_sk AS item_sk,
        cs.cs_call_center_sk AS channel_id,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity,
        COUNT(*) AS transactions,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_filtered df ON cs.cs_sold_date_sk = df.d_date_sk
    GROUP BY cs.cs_item_sk, cs.cs_call_center_sk
),
channel_sales_union AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
),
combined_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_item_desc,
        COALESCE(SUM(CASE WHEN cs.channel = 'store' THEN cs.net_profit END),0) AS store_net_profit,
        COALESCE(SUM(CASE WHEN cs.channel = 'web' THEN cs.net_profit END),0) AS web_net_profit,
        COALESCE(SUM(CASE WHEN cs.channel = 'catalog' THEN cs.net_profit END),0) AS catalog_net_profit,
        COALESCE(SUM(CASE WHEN cs.channel = 'store' THEN cs.quantity END),0) AS store_quantity,
        COALESCE(SUM(CASE WHEN cs.channel = 'web' THEN cs.quantity END),0) AS web_quantity,
        COALESCE(SUM(CASE WHEN cs.channel = 'catalog' THEN cs.quantity END),0) AS catalog_quantity,
        COALESCE(SUM(CASE WHEN cs.channel = 'store' THEN cs.transactions END),0) AS store_transactions,
        COALESCE(SUM(CASE WHEN cs.channel = 'web' THEN cs.transactions END),0) AS web_transactions,
        COALESCE(SUM(CASE WHEN cs.channel = 'catalog' THEN cs.transactions END),0) AS catalog_transactions,
        COALESCE(SUM(CASE WHEN cs.channel = 'store' THEN cs.net_profit END),0) 
          + COALESCE(SUM(CASE WHEN cs.channel = 'web' THEN cs.net_profit END),0) 
          + COALESCE(SUM(CASE WHEN cs.channel = 'catalog' THEN cs.net_profit END),0) AS total_net_profit,
        COALESCE(SUM(CASE WHEN cs.channel = 'store' THEN cs.quantity END),0)
          + COALESCE(SUM(CASE WHEN cs.channel = 'web' THEN cs.quantity END),0)
          + COALESCE(SUM(CASE WHEN cs.channel = 'catalog' THEN cs.quantity END),0) AS total_quantity,
        COALESCE(SUM(CASE WHEN cs.channel = 'store' THEN cs.transactions END),0)
          + COALESCE(SUM(CASE WHEN cs.channel = 'web' THEN cs.transactions END),0)
          + COALESCE(SUM(CASE WHEN cs.channel = 'catalog' THEN cs.transactions END),0) AS total_transactions
    FROM item i
    LEFT JOIN channel_sales_union cs ON i.i_item_sk = cs.item_sk
    GROUP BY i.i_item_sk, i.i_category, i.i_brand, i.i_item_desc
    HAVING COALESCE(SUM(CASE WHEN cs.channel = 'store' THEN cs.net_profit END),0) 
        + COALESCE(SUM(CASE WHEN cs.channel = 'web' THEN cs.net_profit END),0) 
        + COALESCE(SUM(CASE WHEN cs.channel = 'catalog' THEN cs.net_profit END),0) > 0
),
returns_agg AS (
    SELECT 
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM store_returns sr
    LEFT JOIN catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk
    LEFT JOIN web_returns wr ON sr.sr_item_sk = wr.wr_item_sk
    GROUP BY sr.sr_item_sk
),
final AS (
    SELECT 
        cs.i_item_sk,
        cs.i_category,
        cs.i_brand,
        cs.i_item_desc,
        cs.total_net_profit,
        cs.total_quantity,
        cs.total_transactions,
        cs.store_net_profit,
        cs.web_net_profit,
        cs.catalog_net_profit,
        COALESCE(r.store_net_loss,0) AS store_net_loss,
        COALESCE(r.catalog_net_loss,0) AS catalog_net_loss,
        COALESCE(r.web_net_loss,0) AS web_net_loss,
        cs.total_net_profit - COALESCE(r.store_net_loss,0) - COALESCE(r.catalog_net_loss,0) - COALESCE(r.web_net_loss,0) AS net_profit_after_losses,
        ROUND(cs.total_net_profit / NULLIF(cs.total_quantity,0),2) AS profit_per_unit,
        CASE 
            WHEN cs.total_quantity = 0 THEN NULL
            WHEN cs.total_net_profit / cs.total_quantity > 100 THEN 'HIGH'
            WHEN cs.total_net_profit / cs.total_quantity BETWEEN 50 AND 100 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_level,
        (SELECT ROUND(AVG(COALESCE(ss.ss_ext_discount_amt,0) / NULLIF(ss.ss_ext_sales_price,0)),4) 
         FROM store_sales ss 
         WHERE ss.ss_item_sk = cs.i_item_sk) AS avg_store_discount,
        CONCAT(cs.i_item_desc, ' - ', cs.i_brand, ' (', cs.i_category, ')') AS full_description,
        ROW_NUMBER() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank,
        CASE 
            WHEN lower(cs.i_item_desc) LIKE '%red%' AND cs.i_category IN ('Sports','Fashion','Electronics') THEN 1
            ELSE 0
        END AS red_item_flag
    FROM combined_sales cs
    LEFT JOIN returns_agg r ON cs.i_item_sk = r.item_sk
    WHERE cs.total_net_profit > 0 
      AND (cs.total_quantity * cs.total_net_profit) > 10000
)
SELECT 
    profit_rank,
    i_item_sk,
    i_category,
    i_brand,
    full_description,
    total_net_profit,
    total_quantity,
    profit_per_unit,
    profit_level,
    red_item_flag,
    avg_store_discount,
    store_net_profit,
    web_net_profit,
    catalog_net_profit,
    store_net_loss,
    web_net_loss,
    catalog_net_loss,
    net_profit_after_losses
FROM final
WHERE profit_rank <= 50
ORDER BY profit_rank
