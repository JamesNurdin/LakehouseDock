WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_addr_sk,
        ss.ss_cdemo_sk,
        d.d_date_sk AS date_sk,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 0
      AND ss.ss_sales_price > 0
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_promo_sk, ss.ss_addr_sk, ss.ss_cdemo_sk, d.d_date_sk, d.d_year
),
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_promo_sk,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.ws_quantity > 0
    GROUP BY ws.ws_item_sk, ws.ws_promo_sk, d.d_year
),
base AS (
    SELECT
        s.s_store_name,
        d1.d_year,
        i.i_category,
        p.p_promo_name,
        SUM(COALESCE(ssa.store_sales_amount, 0) + COALESCE(wsa.web_sales_amount, 0)) AS total_sales,
        SUM(ssa.total_qty) AS total_quantity
    FROM ss_agg ssa
    LEFT JOIN ws_agg wsa
        ON ssa.ss_item_sk = wsa.ws_item_sk
        AND ssa.d_year = wsa.d_year
    JOIN store s ON ssa.ss_store_sk = s.s_store_sk
    JOIN item i ON ssa.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ssa.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d1 ON ssa.date_sk = d1.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d1.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d1.d_date_sk
    JOIN customer_address ca ON ssa.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ssa.ss_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_brand = 'Brand#45'
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'monthly'
      AND p.p_channel_catalog = 'N'
    GROUP BY ROLLUP (s.s_store_name, d1.d_year, i.i_category, p.p_promo_name)
)
SELECT
    b.s_store_name,
    b.d_year,
    b.i_category,
    b.p_promo_name,
    b.total_sales,
    b.total_quantity,
    CASE WHEN b.total_quantity > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category,
    ROW_NUMBER() OVER (PARTITION BY b.s_store_name ORDER BY b.total_sales DESC) AS sales_rank
FROM base b
ORDER BY b.total_sales DESC
LIMIT 100
