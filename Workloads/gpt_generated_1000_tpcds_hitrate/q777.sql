WITH
    /* Aggregate web sales by site and billing household */
    sales_detail AS (
        SELECT
            ws_web_site_sk,
            ws_bill_hdemo_sk,
            ws_ship_hdemo_sk,
            SUM(ws_ext_sales_price) AS total_sales,
            SUM(ws_quantity) AS total_qty,
            AVG(ws_ext_discount_amt) AS avg_discount
        FROM web_sales
        WHERE ws_ext_sales_price > 100            -- filter 1: high‑value sales
          AND ws_quantity >= 1                    -- filter 2: at least one item
          AND ws_list_price BETWEEN 10 AND 300   -- filter 3: realistic price range
        GROUP BY ws_web_site_sk, ws_bill_hdemo_sk, ws_ship_hdemo_sk
    ),
    /* Filtered web sites (dimension) */
    site_filtered AS (
        SELECT
            web_site_sk,
            web_name,
            web_state,
            web_gmt_offset,
            web_close_date_sk
        FROM web_site
        WHERE web_state = 'CA'                     -- filter 4: California sites
          AND web_gmt_offset >= -8                 -- filter 5: reasonable GMT offset
          AND web_close_date_sk > 2441500         -- filter 6: recent closure key
    ),
    /* Filtered household demographics (dimension) */
    demo_filtered AS (
        SELECT
            hd_demo_sk,
            hd_dep_count,
            hd_buy_potential,
            hd_income_band_sk
        FROM household_demographics
        WHERE hd_dep_count >= 2                     -- filter 7: families with at least 2 dependents
          AND hd_buy_potential = '1001-5000'       -- filter 8: medium buying potential
          AND hd_income_band_sk IN (10,12,20)       -- filter 9: selected income bands
    ),
    /* INTERSECT of site keys that appear in sales and those that survive the site filter */
    intersected_sites AS (
        SELECT web_site_sk FROM site_filtered
        INTERSECT
        SELECT ws_web_site_sk FROM sales_detail
    )
SELECT
    sf.ws_web_site_sk,
    s.web_name,
    s.web_state,
    hd.hd_dep_count,
    hd.hd_buy_potential,
    sf.total_sales,
    sf.total_qty,
    sf.avg_discount,
    CASE
        WHEN sf.total_sales > 100000 THEN 'High'
        WHEN sf.total_sales > 50000  THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    /* Correlated scalar subquery: total sales for the same state across all sites */
    (SELECT SUM(s2.total_sales)
     FROM sales_detail s2
     JOIN site_filtered sf2 ON s2.ws_web_site_sk = sf2.web_site_sk
     WHERE sf2.web_state = s.web_state) AS state_total_sales,
    /* Correlated scalar subquery: count of households matching the current household's buying potential and dependent count */
    (SELECT COUNT(*)
     FROM household_demographics hd2
     WHERE hd2.hd_buy_potential = hd.hd_buy_potential
       AND hd2.hd_dep_count = hd.hd_dep_count) AS matching_household_cnt
FROM sales_detail sf
RIGHT OUTER JOIN site_filtered s
    ON sf.ws_web_site_sk = s.web_site_sk
LEFT JOIN household_demographics hd
    ON sf.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE s.web_site_sk IN (SELECT web_site_sk FROM intersected_sites)   -- keep only intersected keys
ORDER BY sales_category DESC, sf.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
