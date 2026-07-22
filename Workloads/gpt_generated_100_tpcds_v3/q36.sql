WITH distinct_items AS (
    SELECT DISTINCT i.i_item_sk,
                    i.i_item_id,
                    i.i_brand,
                    i.i_category
    FROM item i
    WHERE i.i_size = 'medium'
),
sales_agg AS (
    SELECT
        di.i_item_id,
        di.i_brand,
        di.i_category,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN distinct_items di ON ws.ws_item_sk = di.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_ship_date_sk BETWEEN 2452200 AND 2452300
      AND ca.ca_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = ws.ws_promo_sk
            AND p.p_item_sk = di.i_item_sk
            AND p.p_discount_active = 'Y'
      )
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_char_count > 3000
      )
    GROUP BY di.i_item_id, di.i_brand, di.i_category, ca.ca_state
)
SELECT
    i_brand,
    i_category,
    ca_state,
    AVG(total_profit) AS avg_profit_per_item,
    SUM(sales_cnt) AS total_sales
FROM sales_agg
GROUP BY i_brand, i_category, ca_state
HAVING SUM(sales_cnt) > 5
ORDER BY avg_profit_per_item DESC
LIMIT 100
