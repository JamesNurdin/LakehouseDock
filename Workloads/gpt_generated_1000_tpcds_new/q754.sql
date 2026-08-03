WITH ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
),
ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        sm.sm_type,
        w.w_warehouse_name,
        site.web_name,
        CASE
            WHEN ws.ws_net_paid > 1000 THEN 'HIGH'
            WHEN ws.ws_net_paid > 500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS revenue_category,
        -- LATERAL sub‑query that creates an array from two numeric columns and unnests it
        unnested_val.val AS unnested_metric
    FROM ws_sample ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    -- LATERAL UNNEST – references columns from the preceding relation (ws)
    CROSS JOIN LATERAL (
        SELECT val
        FROM UNNEST(array[ws.ws_quantity, ws.ws_net_paid]) AS t(val)
    ) AS unnested_val
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451175                     -- filter 1
      AND ca.ca_state = 'CA'                                                -- filter 2
      AND cd.cd_gender = 'M'                                                -- filter 3
      AND ib.ib_upper_bound > 80000                                         -- filter 4
      AND p.p_discount_active = 'Y'                                         -- filter 5
),
cs_base AS (
    SELECT
        cs.cs_order_number      AS order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cc.cc_name,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451175                     -- filter 6
      AND cc.cc_state = 'CA'                                                -- filter 7 (cc_state exists in DDL)
      AND cc.cc_tax_percentage > 5.0                                      -- filter 8
      AND cs.cs_quantity > 2                                               -- filter 9
      AND cs.cs_net_paid > 200                                             -- filter10
),
union_all AS (
    SELECT
        ws_order_number        AS order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_paid,
        revenue_category,
        ca_state,
        cd_gender,
        ib_upper_bound,
        p_promo_name,
        sm_type,
        w_warehouse_name,
        web_name,
        'WEB'      AS source
    FROM ws_base
    UNION DISTINCT
    SELECT
        order_number,
        NULL        AS ws_sold_date_sk,
        cs_quantity,
        cs_net_paid,
        NULL        AS revenue_category,
        NULL        AS ca_state,
        NULL        AS cd_gender,
        NULL        AS ib_upper_bound,
        NULL        AS p_promo_name,
        NULL        AS sm_type,
        NULL        AS w_warehouse_name,
        NULL        AS web_name,
        'CATALOG'   AS source
    FROM cs_base
),
final_rank AS (
    SELECT
        order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_paid,
        revenue_category,
        ca_state,
        cd_gender,
        ib_upper_bound,
        p_promo_name,
        sm_type,
        w_warehouse_name,
        web_name,
        source,
        ROW_NUMBER() OVER (PARTITION BY source ORDER BY ws_net_paid DESC NULLS LAST) AS rn_source,
        RANK()        OVER (ORDER BY ws_net_paid DESC NULLS LAST)               AS overall_rank
    FROM union_all
    WHERE order_number IN (
        SELECT wr.wr_order_number
        FROM web_returns wr
        WHERE wr.wr_return_tax > 20                                          -- subquery filter
    )
)
SELECT *
FROM final_rank
ORDER BY overall_rank
LIMIT 100
