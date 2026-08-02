WITH catalog_sales_agg AS (
    SELECT
        cc.cc_call_center_sk AS entity_id,
        cc.cc_name AS entity_name,
        SUM(cs.cs_net_profit) AS total_amount,
        CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM
        catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE
        cp.cp_type = 'monthly'
        AND cp.cp_catalog_page_id = 'AAAAAAAALAAAAAAA'
        AND cs.cs_ext_sales_price > 1000
        AND cs.cs_sold_date_sk BETWEEN 2451054 AND 2451144
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name
),
store_returns_agg AS (
    SELECT
        sr.sr_store_sk AS entity_id,
        ca.ca_state AS entity_name,
        SUM(sr.sr_net_loss) AS total_amount,
        CASE WHEN SUM(sr.sr_net_loss) > 50000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM
        store_returns sr
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_country = 'United States'
        AND sr.sr_return_amt > 500
    GROUP BY
        sr.sr_store_sk,
        ca.ca_state
)
SELECT
    'Catalog Sales' AS source,
    cs_agg.entity_id,
    cs_agg.entity_name,
    cs_agg.total_amount,
    cs_agg.amount_category
FROM catalog_sales_agg cs_agg
UNION
SELECT
    'Store Returns' AS source,
    sr_agg.entity_id,
    sr_agg.entity_name,
    sr_agg.total_amount,
    sr_agg.amount_category
FROM store_returns_agg sr_agg
LIMIT 100
