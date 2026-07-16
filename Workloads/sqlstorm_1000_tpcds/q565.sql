WITH max_year AS (
    SELECT max(d_year) AS yr FROM date_dim
),
sales_all AS (
    SELECT 'catalog' AS src,
           cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_promo_sk AS promo_sk,
           cs.cs_order_number AS order_number,
           cs.cs_quantity AS quantity
    FROM catalog_sales cs
    UNION ALL
    SELECT 'store' AS src,
           ss.ss_sold_date_sk,
           ss.ss_customer_sk,
           ss.ss_item_sk,
           ss.ss_net_profit,
           ss.ss_promo_sk,
           ss.ss_ticket_number,
           ss.ss_quantity
    FROM store_sales ss
    UNION ALL
    SELECT 'web' AS src,
           ws.ws_sold_date_sk,
           ws.ws_bill_customer_sk,
           ws.ws_item_sk,
           ws.ws_net_profit,
           ws.ws_promo_sk,
           ws.ws_order_number,
           ws.ws_quantity
    FROM web_sales ws
),
sales_enhanced AS (
    SELECT sa.*,
           d.d_year,
           c.c_first_name,
           c.c_last_name,
           ca.ca_city,
           ca.ca_state,
           p.p_promo_name,
           p.p_discount_active,
           CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS promotion_flag
    FROM sales_all sa
    LEFT JOIN date_dim d ON sa.sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON sa.customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p ON sa.promo_sk = p.p_promo_sk
),
yearly_profit AS (
    SELECT customer_sk,
           d_year,
           sum(net_profit) AS yearly_profit,
           sum(net_profit) FILTER (WHERE promotion_flag = 1) AS promo_profit,
           sum(quantity) AS total_quantity
    FROM sales_enhanced
    GROUP BY customer_sk, d_year
),
prior_avg AS (
    SELECT customer_sk,
           avg(yearly_profit) AS avg_prior_profit,
           avg(promo_profit) AS avg_prior_promo_profit
    FROM yearly_profit yp
    WHERE yp.d_year < (SELECT yr FROM max_year)
    GROUP BY customer_sk
),
latest_year_ranked AS (
    SELECT yp.*,
           row_number() OVER (PARTITION BY d_year ORDER BY yearly_profit DESC) AS profit_rank
    FROM yearly_profit yp
    WHERE yp.d_year = (SELECT yr FROM max_year)
),
latest_year_details AS (
    SELECT ly.customer_sk,
           ly.yearly_profit,
           ly.promo_profit,
           ly.total_quantity,
           ly.profit_rank,
           c.c_first_name,
           c.c_last_name,
           coalesce(ca.ca_city, 'UNKNOWN') AS city,
           pa.avg_prior_profit,
           pa.avg_prior_promo_profit,
           ly.yearly_profit / nullif(pa.avg_prior_profit, 0) AS profit_ratio,
           ly.promo_profit / nullif(pa.avg_prior_promo_profit, 0) AS promo_profit_ratio,
           (SELECT sum(se2.net_profit)
            FROM sales_enhanced se2
            WHERE se2.customer_sk = ly.customer_sk
              AND se2.d_year = ly.d_year - 1) AS prior_year_profit
    FROM latest_year_ranked ly
    LEFT JOIN customer c ON ly.customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN prior_avg pa ON ly.customer_sk = pa.customer_sk
    WHERE ly.profit_rank <= 100
),
item_promo AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           max(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS has_active_discount
    FROM item i
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    GROUP BY i.i_item_sk, i.i_product_name
),
top_items AS (
    SELECT item_sk,
           sum(net_profit) AS profit_sum
    FROM sales_all
    GROUP BY item_sk
    ORDER BY profit_sum DESC
    LIMIT 10
),
promoted_top_items AS (
    SELECT ip.i_item_sk,
           ip.i_product_name,
           ip.has_active_discount
    FROM item_promo ip
    JOIN top_items ti ON ip.i_item_sk = ti.item_sk
    WHERE ip.has_active_discount = 1
),
combined_entities AS (
    SELECT 'Customer' AS entity_type,
           ld.customer_sk AS entity_id,
           concat_ws(' ', ld.c_first_name, ld.c_last_name) AS description,
           concat('City:', ld.city) AS extra_info
    FROM latest_year_details ld
    UNION ALL
    SELECT 'Item' AS entity_type,
           pt.i_item_sk AS entity_id,
           pt.i_product_name AS description,
           concat('DiscountActive:', CAST(pt.has_active_discount AS VARCHAR)) AS extra_info
    FROM promoted_top_items pt
)SELECT * FROM combined_entities
