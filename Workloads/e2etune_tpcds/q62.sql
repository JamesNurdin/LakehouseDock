WITH catalog_agg AS (
    SELECT
        cc.cc_division,
        cc.cc_state,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_gmt_offset = -5.00
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cc.cc_division, cc.cc_state
),
store_return_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count,
        AVG(sr.sr_return_quantity) AS avg_return_qty
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ss.ss_store_sk, ss.ss_hdemo_sk
)
SELECT
    source,
    division,
    state,
    total_sales,
    avg_profit,
    distinct_orders,
    store_sk,
    hdemo_sk,
    total_return_loss,
    return_count,
    avg_return_qty,
    RANK() OVER (PARTITION BY source ORDER BY
        CASE
            WHEN source = 'catalog' THEN total_sales
            WHEN source = 'store_return' THEN total_return_loss
        END DESC NULLS LAST) AS rank_in_source
FROM (
    SELECT
        'catalog' AS source,
        ca.cc_division AS division,
        ca.cc_state AS state,
        ca.total_sales,
        ca.avg_profit,
        ca.distinct_orders,
        CAST(NULL AS INTEGER) AS store_sk,
        CAST(NULL AS INTEGER) AS hdemo_sk,
        CAST(NULL AS DECIMAL(7,2)) AS total_return_loss,
        CAST(NULL AS INTEGER) AS return_count,
        CAST(NULL AS DOUBLE) AS avg_return_qty
    FROM catalog_agg ca
    UNION ALL
    SELECT
        'store_return' AS source,
        CAST(NULL AS INTEGER) AS division,
        CAST(NULL AS VARCHAR) AS state,
        CAST(NULL AS DECIMAL(7,2)) AS total_sales,
        CAST(NULL AS DECIMAL(7,2)) AS avg_profit,
        CAST(NULL AS INTEGER) AS distinct_orders,
        sra.ss_store_sk AS store_sk,
        sra.ss_hdemo_sk AS hdemo_sk,
        sra.total_return_loss,
        sra.return_count,
        sra.avg_return_qty
    FROM store_return_agg sra
) combined
ORDER BY source, rank_in_source
