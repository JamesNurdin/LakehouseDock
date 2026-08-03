WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_item_id,
        cc.cc_name,
        cp.cp_department,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        COALESCE(inv.inv_quantity_on_hand, 0)        AS inv_quantity_on_hand,
        COALESCE(wr.wr_return_quantity, 0)          AS wr_return_quantity,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        ws.ws_web_site_sk,
        ws_site.web_mkt_desc
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws        ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_site    ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wr      ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (5, 10)
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'promo'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '5001-10000'
      AND ib.ib_lower_bound > 30000
      AND ws_site.web_mkt_desc LIKE '%technical%'
),
store_base AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_item_id,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        COALESCE(inv.inv_quantity_on_hand, 0) AS inv_quantity_on_hand,
        ss.ss_quantity,
        ss.ss_ext_sales_price
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category_id = 5
      AND cd.cd_gender = 'F'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound < 80000
),
cat_agg AS (
    SELECT
        d_year,
        i_category,
        i_brand,
        'catalog' AS source,
        SUM(cs_ext_sales_price)          AS total_sales,
        SUM(cs_quantity)                 AS total_qty,
        SUM(inv_quantity_on_hand)        AS total_inventory,
        SUM(wr_return_quantity)          AS total_returns
    FROM base
    GROUP BY ROLLUP (d_year, i_category, i_brand)
),
store_agg AS (
    SELECT
        d_year,
        i_category,
        i_brand,
        'store' AS source,
        SUM(ss_ext_sales_price)          AS total_sales,
        SUM(ss_quantity)                 AS total_qty,
        SUM(inv_quantity_on_hand)        AS total_inventory,
        0                                 AS total_returns
    FROM store_base
    GROUP BY ROLLUP (d_year, i_category, i_brand)
),
union_agg AS (
    SELECT * FROM cat_agg
    UNION DISTINCT
    SELECT * FROM store_agg
),
ranked AS (
    SELECT
        d_year,
        i_category,
        i_brand,
        source,
        total_sales,
        total_qty,
        total_inventory,
        total_returns,
        ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY total_sales DESC) AS rnk
    FROM union_agg
)
SELECT
    d_year,
    i_category,
    i_brand,
    source,
    total_sales,
    total_qty,
    total_inventory,
    total_returns,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper
FROM ranked
WHERE rnk <= 5
ORDER BY d_year, i_category, total_sales DESC
LIMIT 100
