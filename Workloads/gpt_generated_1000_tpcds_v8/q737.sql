WITH
    joined AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_item_sk,
            ws.ws_quantity,
            ws.ws_sales_price,
            ws.ws_ext_sales_price,
            ws.ws_net_profit,
            ws.ws_warehouse_sk,
            ws.ws_promo_sk,
            ws.ws_bill_customer_sk,
            ws.ws_bill_hdemo_sk,
            ws.ws_bill_addr_sk,
            ws.ws_ship_hdemo_sk,
            ws.ws_ship_addr_sk,
            i.i_item_id,
            i.i_brand,
            i.i_category,
            p.p_promo_name,
            w.w_warehouse_name,
            w.w_country,
            w.w_state,
            ca_bill.ca_city AS bill_city,
            ca_ship.ca_city AS ship_city,
            hd_bill.hd_income_band_sk AS bill_income_band,
            hd_ship.hd_income_band_sk AS ship_income_band,
            wp.wp_url,
            t.t_hour,
            t.t_meal_time
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    ),
    excluded_orders AS (
        SELECT ws_order_number FROM web_sales WHERE ws_quantity = 1
        EXCEPT
        SELECT ws_order_number FROM web_sales WHERE ws_ext_discount_amt = 0
    ),
    agg_by_warehouse AS (
        SELECT
            w_country,
            w_state,
            w_warehouse_name,
            SUM(ws_ext_sales_price) AS total_sales,
            AVG(ws_sales_price) AS avg_price,
            MAX(ws_net_profit) AS max_profit,
            COUNT(*) AS order_cnt
        FROM joined
        WHERE ws_order_number NOT IN (SELECT ws_order_number FROM excluded_orders)
        GROUP BY w_country, w_state, w_warehouse_name
    ),
    agg_by_brand AS (
        SELECT
            i_brand,
            SUM(ws_ext_sales_price) AS total_sales,
            AVG(ws_sales_price) AS avg_price,
            MAX(ws_net_profit) AS max_profit,
            COUNT(*) AS order_cnt
        FROM joined
        WHERE ws_order_number NOT IN (SELECT ws_order_number FROM excluded_orders)
        GROUP BY i_brand
    ),
    union_agg AS (
        SELECT
            w_country AS country,
            w_state AS state,
            NULL AS brand,
            total_sales,
            avg_price,
            max_profit,
            order_cnt
        FROM agg_by_warehouse
        UNION
        SELECT
            NULL,
            NULL,
            i_brand,
            total_sales,
            avg_price,
            max_profit,
            order_cnt
        FROM agg_by_brand
    ),
    intersect_agg AS (
        SELECT w_country, w_state, total_sales
        FROM agg_by_warehouse
        INTERSECT
        SELECT w_country, w_state, total_sales
        FROM agg_by_warehouse
        WHERE max_profit > 0
    ),
    detailed AS (
        SELECT
            j.ws_order_number,
            j.ws_item_sk,
            j.ws_sold_date_sk,
            j.w_warehouse_name,
            j.w_country,
            j.w_state,
            a.total_sales,
            a.avg_price,
            a.max_profit,
            a.order_cnt
        FROM joined j
        JOIN agg_by_warehouse a ON j.w_warehouse_name = a.w_warehouse_name
        WHERE j.ws_order_number NOT IN (SELECT ws_order_number FROM excluded_orders)
    )
SELECT
    d.w_warehouse_name,
    d.w_country,
    d.w_state,
    d.total_sales,
    d.avg_price,
    d.max_profit,
    d.order_cnt,
    LAG(d.max_profit) OVER (PARTITION BY d.w_country ORDER BY d.total_sales DESC) AS prev_max_profit,
    (SELECT AVG(ws_sales_price)
       FROM web_sales ws2
      WHERE ws2.ws_item_sk = d.ws_item_sk
        AND ws2.ws_sold_date_sk = d.ws_sold_date_sk) AS avg_price_same_item_day,
    ROW_NUMBER() OVER (PARTITION BY d.w_country ORDER BY d.total_sales DESC) AS rank_by_sales
FROM detailed d
WHERE d.ws_order_number NOT IN (SELECT ws_order_number FROM excluded_orders)

UNION

SELECT
    NULL AS w_warehouse_name,
    ua.country,
    ua.state,
    ua.total_sales,
    ua.avg_price,
    ua.max_profit,
    ua.order_cnt,
    NULL AS prev_max_profit,
    NULL AS avg_price_same_item_day,
    NULL AS rank_by_sales
FROM union_agg ua
WHERE ua.brand IS NULL

INTERSECT

SELECT
    i.w_warehouse_name,
    i.w_country,
    i.w_state,
    i.total_sales,
    i.avg_price,
    i.max_profit,
    i.order_cnt,
    NULL AS prev_max_profit,
    NULL AS avg_price_same_item_day,
    NULL AS rank_by_sales
FROM intersect_agg ia
JOIN agg_by_warehouse i
  ON ia.w_country = i.w_country
 AND ia.w_state = i.w_state
 AND ia.total_sales = i.total_sales
LIMIT 100
