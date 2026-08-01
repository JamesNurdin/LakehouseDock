WITH sales_agg AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_web_site_sk
),
joined AS (
    SELECT
        sd.d_date,
        sd.d_year,
        t.t_hour,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        p.p_promo_name,
        s.s_store_name,
        wp.wp_type,
        wsite.web_site_sk,
        wsite.web_market_manager,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_ship_date_sk AS ship_date_sk,
        ws.ws_web_page_sk,
        ws.ws_promo_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_ship_hdemo_sk,
        agg.total_sales,
        agg.total_qty
    FROM sales_agg agg
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = agg.ws_sold_date_sk
       AND ws.ws_web_site_sk = agg.ws_web_site_sk
    RIGHT OUTER JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN date_dim sd
        ON ws.ws_sold_date_sk = sd.d_date_sk
    LEFT JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = sd.d_date_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sd.d_year = 2001
      AND wsite.web_market_manager = 'David Myers'
      AND hd.hd_buy_potential = '5001-10000'
)
SELECT *
FROM (
    SELECT
        d_date,
        web_site_sk,
        total_sales,
        total_qty,
        cd_gender,
        hd_buy_potential,
        CASE WHEN total_sales > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY web_site_sk ORDER BY total_sales DESC) AS rn,
        (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_start_date_sk = joined.sold_date_sk) AS avg_promo_cost,
        EXISTS (
            SELECT 1 FROM web_sales ws_sub
            WHERE ws_sub.ws_web_site_sk = joined.web_site_sk
              AND ws_sub.ws_quantity > 5
        ) AS has_large_qty
    FROM joined
    WHERE total_qty > 0

    UNION DISTINCT

    SELECT
        d_date,
        web_site_sk,
        total_sales,
        total_qty,
        cd_gender,
        hd_buy_potential,
        CASE WHEN total_sales > 5000 THEN 'Medium' ELSE 'Low' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY web_site_sk ORDER BY total_sales ASC) AS rn,
        (SELECT MAX(p3.p_cost) FROM promotion p3 WHERE p3.p_end_date_sk = joined.ship_date_sk) AS avg_promo_cost,
        EXISTS (
            SELECT 1 FROM web_sales ws_sub2
            WHERE ws_sub2.ws_web_site_sk = joined.web_site_sk
              AND ws_sub2.ws_quantity < 2
        ) AS has_large_qty
    FROM joined
    WHERE total_qty > 0
) AS unioned
EXCEPT
SELECT
    d_date,
    web_site_sk,
    total_sales,
    total_qty,
    cd_gender,
    hd_buy_potential,
    sales_category,
    rn,
    avg_promo_cost,
    has_large_qty
FROM (
    SELECT
        d_date,
        web_site_sk,
        total_sales,
        total_qty,
        cd_gender,
        hd_buy_potential,
        CASE WHEN total_sales > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY web_site_sk ORDER BY total_sales DESC) AS rn,
        (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_start_date_sk = joined.sold_date_sk) AS avg_promo_cost,
        EXISTS (
            SELECT 1 FROM web_sales ws_sub
            WHERE ws_sub.ws_web_site_sk = joined.web_site_sk
              AND ws_sub.ws_quantity > 5
        ) AS has_large_qty
    FROM joined
    WHERE total_qty > 0
) AS excluded
ORDER BY total_sales DESC
LIMIT 100
