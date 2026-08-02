WITH joined_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        ws.ws_wholesale_cost,
        ws.ws_coupon_amt,
        ws.ws_ext_ship_cost,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_formulation,
        i.i_wholesale_cost,
        i.i_category,
        i.i_color,
        i.i_container,
        wp.wp_web_page_sk,
        wp.wp_type,
        wp.wp_link_count,
        wp.wp_web_page_id
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_wholesale_cost > 30
      AND ws.ws_coupon_amt < 5000
      AND ws.ws_ext_ship_cost BETWEEN 100 AND 5000
      AND i.i_formulation LIKE '%goldenrod%'
      AND wp.wp_link_count >= 10
), agg_sales AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        wp_type,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        SUM(ws_ext_discount_amt) AS total_discount,
        CASE WHEN SUM(ws_ext_discount_amt) > 5000 THEN 'High' ELSE 'Low' END AS discount_level
    FROM joined_sales
    GROUP BY i_item_sk, i_product_name, i_brand, wp_type
), intersect_items AS (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_wholesale_cost > 60
    INTERSECT
    SELECT i_item_sk
    FROM item
    WHERE i_wholesale_cost > 1
), ranked_sales AS (
    SELECT
        a.*, 
        RANK() OVER (PARTITION BY i_brand ORDER BY total_sales DESC) AS brand_sales_rank
    FROM agg_sales a
)
SELECT
    rs.i_item_sk,
    rs.i_product_name,
    rs.i_brand,
    rs.wp_type,
    rs.total_sales,
    rs.total_profit,
    rs.order_cnt,
    rs.discount_level,
    rs.brand_sales_rank,
    (SELECT AVG(ws_net_profit) FROM web_sales) AS overall_avg_profit
FROM ranked_sales rs
WHERE rs.total_sales > 10000
  AND rs.total_profit > 5000
  AND rs.order_cnt >= 5
  AND rs.discount_level = 'High'
  AND rs.i_item_sk IN (SELECT ws_item_sk FROM intersect_items)
ORDER BY rs.total_sales DESC
LIMIT 100
