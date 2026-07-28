WITH inventory_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        MAX(ia.total_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        AVG(p.p_cost) AS avg_promo_cost,
        MIN(ib.ib_lower_bound) AS min_income_lower,
        MAX(ib.ib_upper_bound) AS max_income_upper
    FROM item i
    JOIN inventory_agg ia ON i.i_item_sk = ia.inv_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON s.s_store_sk = ss.ss_store_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t ON t.t_time_sk = ss.ss_sold_time_sk
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    WHERE t.t_hour = 14
      AND i.i_brand = 'Brand#12'
      AND p.p_response_target = 1
      AND s.s_state = 'CA'
      AND wp.wp_max_ad_count = 0
    GROUP BY i.i_item_id, i.i_product_name, s.s_store_name, s.s_state
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    i_item_id,
    i_product_name,
    s_store_name,
    s_state,
    total_store_sales,
    total_web_sales,
    total_inventory,
    distinct_customers,
    avg_promo_cost,
    min_income_lower,
    max_income_upper,
    RANK() OVER (ORDER BY total_store_sales DESC) AS sales_rank
FROM item_sales
ORDER BY total_store_sales DESC
LIMIT 100
