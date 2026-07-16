WITH
sales_union AS (
    SELECT
        ss_sold_date_sk AS sales_date_sk,
        ss_store_sk AS entity_sk,
        'store' AS channel,
        ss_quantity AS quantity,
        ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_call_center_sk,
        'catalog',
        cs_quantity,
        cs_net_profit
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_web_site_sk,
        'web',
        ws_quantity,
        ws_net_profit
    FROM web_sales
),
returns_union AS (
    SELECT
        sr_returned_date_sk AS return_date_sk,
        sr_store_sk AS entity_sk,
        'store' AS channel,
        sr_return_quantity AS quantity,
        sr_net_loss AS net_loss
    FROM store_returns
    UNION ALL
    SELECT
        cr_returned_date_sk,
        cr_call_center_sk,
        'catalog',
        cr_return_quantity,
        cr_net_loss
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        NULL,
        'web',
        wr_return_quantity,
        wr_net_loss
    FROM web_returns
),
sales_agg AS (
    SELECT
        date_trunc('month', d.d_date) AS month_date,
        s.entity_sk,
        s.channel,
        SUM(s.quantity) AS total_quantity,
        SUM(s.net_profit) AS total_net_profit
    FROM sales_union s
    LEFT JOIN date_dim d ON d.d_date_sk = s.sales_date_sk
    GROUP BY 1,2,3
),
returns_agg AS (
    SELECT
        date_trunc('month', d.d_date) AS month_date,
        r.entity_sk,
        r.channel,
        SUM(r.quantity) AS total_return_quantity,
        SUM(r.net_loss) AS total_net_loss
    FROM returns_union r
    LEFT JOIN date_dim d ON d.d_date_sk = r.return_date_sk
    GROUP BY 1,2,3
),
intersected_entities AS (
    SELECT entity_sk, channel FROM sales_agg
    INTERSECT
    SELECT entity_sk, channel FROM returns_agg
),
combined AS (
    SELECT
        s.month_date,
        s.entity_sk,
        s.channel,
        s.total_quantity,
        s.total_net_profit,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        (s.total_quantity - COALESCE(r.total_return_quantity, 0)) AS net_quantity_sold,
        (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_adj,
        CASE
            WHEN s.total_quantity = 0 THEN NULL
            ELSE CAST(COALESCE(r.total_return_quantity, 0) AS DOUBLE) / s.total_quantity
        END AS return_quantity_ratio,
        CASE
            WHEN s.total_net_profit = 0 THEN NULL
            ELSE COALESCE(r.total_net_loss, 0) / s.total_net_profit
        END AS return_loss_ratio,
        CONCAT(
            CASE WHEN s.entity_sk IS NULL THEN 'NULL' ELSE CAST(s.entity_sk AS VARCHAR) END,
            '-',
            s.channel
        ) AS entity_channel_key,
        LAG(s.total_net_profit) OVER (PARTITION BY s.entity_sk, s.channel ORDER BY s.month_date) AS prior_month_profit,
        ROW_NUMBER() OVER (PARTITION BY s.entity_sk, s.channel ORDER BY s.month_date DESC) AS rn_desc
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.month_date = r.month_date
        AND s.entity_sk = r.entity_sk
        AND s.channel = r.channel
),
final AS (
    SELECT
        c.month_date,
        c.entity_sk,
        c.channel,
        COALESCE(st.s_store_name, cc.cc_name, 'WEB') AS entity_name,
        c.total_quantity,
        c.total_net_profit,
        c.total_return_quantity,
        c.total_net_loss,
        c.net_quantity_sold,
        c.net_profit_adj,
        c.return_quantity_ratio,
        c.return_loss_ratio,
        c.entity_channel_key,
        regexp_replace(c.entity_channel_key, '[0-9]', '') AS entity_key_alpha,
        c.prior_month_profit,
        c.rn_desc,
        CASE
            WHEN c.rn_desc = 1 THEN 'LATEST'
            WHEN c.rn_desc = 2 THEN 'SECOND_LATEST'
            ELSE 'OLDER'
        END AS recency_flag,
        (SELECT MAX(sa.total_net_profit)
         FROM sales_agg sa
         WHERE sa.entity_sk = c.entity_sk AND sa.channel = c.channel) AS max_monthly_profit,
        CASE
            WHEN TRY_CAST(c.entity_channel_key AS INTEGER) IS NULL THEN 'NON_NUMERIC_KEY'
            ELSE 'NUMERIC_KEY'
        END AS key_type,
        CASE
            WHEN c.net_profit_adj > 0
                AND c.return_loss_ratio IS NOT NULL
                AND c.return_loss_ratio > 0.5 THEN 'HIGH_LOSS_RISK'
            ELSE NULL
        END AS risk_flag,
        length(COALESCE(st.s_store_name, cc.cc_name, 'WEB')) AS entity_name_len,
        NULLIF(c.total_quantity - c.total_return_quantity, 0) AS adjusted_quantity,
        SUM(c.total_net_profit) OVER (PARTITION BY c.entity_sk, c.channel ORDER BY c.month_date ROWS UNBOUNDED PRECEDING) AS cumulative_profit
    FROM combined c
    LEFT JOIN store st ON c.channel = 'store' AND c.entity_sk = st.s_store_sk
    LEFT JOIN call_center cc ON c.channel = 'catalog' AND c.entity_sk = cc.cc_call_center_sk
    WHERE (c.rn_desc <= 3 OR c.return_quantity_ratio > 0.1)
      AND NOT EXISTS (
          SELECT 1
          FROM returns_agg r2
          WHERE r2.entity_sk = c.entity_sk
            AND r2.channel = c.channel
            AND r2.month_date = c.month_date
            AND r2.total_return_quantity > c.total_quantity * 2
      )
      AND EXISTS (SELECT 1 FROM intersected_entities i WHERE i.entity_sk = c.entity_sk AND i.channel = c.channel)
)
SELECT *
FROM final
WHERE (net_quantity_sold IS NOT NULL AND net_quantity_sold > 0)
   OR (risk_flag IS NOT NULL)
ORDER BY month_date DESC, entity_name
LIMIT 200
