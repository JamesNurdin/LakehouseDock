WITH
    store_agg AS (
        SELECT
            ss.ss_item_sk,
            ss.ss_store_sk,
            ss.ss_customer_sk,
            SUM(ss.ss_net_paid) AS store_net_paid,
            SUM(ss.ss_quantity) AS store_quantity
        FROM
            store_sales ss
            JOIN item i ON ss.ss_item_sk = i.i_item_sk
            JOIN store s ON ss.ss_store_sk = s.s_store_sk
            JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
            JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
            JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        WHERE
            i.i_brand = 'Brand#23'
            AND s.s_state = 'NY'
            AND cd.cd_gender = 'M'
            AND hd.hd_buy_potential = '5000-9999'
        GROUP BY
            ss.ss_item_sk,
            ss.ss_store_sk,
            ss.ss_customer_sk
    ),
    catalog_agg AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_call_center_sk,
            cs.cs_ship_mode_sk,
            cs.cs_catalog_page_sk,
            SUM(cs.cs_net_paid) AS catalog_net_paid,
            SUM(cs.cs_quantity) AS catalog_quantity
        FROM
            catalog_sales cs
            JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
            JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
            JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        GROUP BY
            cs.cs_item_sk,
            cs.cs_call_center_sk,
            cs.cs_ship_mode_sk,
            cs.cs_catalog_page_sk
    )
SELECT
    DISTINCT i.i_item_id,
    s.s_store_name,
    sa.store_net_paid,
    sa.store_quantity,
    ca.catalog_net_paid,
    ca.catalog_quantity
FROM
    store_agg sa
    JOIN catalog_agg ca ON sa.ss_item_sk = ca.cs_item_sk
    JOIN item i ON sa.ss_item_sk = i.i_item_sk
    JOIN store s ON sa.ss_store_sk = s.s_store_sk
WHERE
    -- semi‑join using EXISTS to bring in web_returns
    EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = sa.ss_item_sk
          AND wr.wr_return_quantity > 0
    )
    -- compare against a scalar sub‑query that returns a single value
    AND sa.store_net_paid > (
        SELECT AVG(cs.cs_net_paid)
        FROM catalog_sales cs
    )
GROUP BY
    i.i_item_id,
    s.s_store_name,
    sa.store_net_paid,
    sa.store_quantity,
    ca.catalog_net_paid,
    ca.catalog_quantity
HAVING
    SUM(sa.store_quantity) > 100
ORDER BY
    sa.store_net_paid DESC
LIMIT 100
