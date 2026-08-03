WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        p.p_promo_name,
        p.p_discount_active,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ca.ca_state,
        cu.c_first_name,
        cu.c_last_name,
        cu.c_birth_year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 50
      AND ib.ib_lower_bound >= 30000
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 1
),
inv_items AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        inv.inv_quantity_on_hand
    FROM inventory inv
    RIGHT OUTER JOIN item i ON inv.inv_item_sk = i.i_item_sk
),
common_customers AS (
    SELECT cs_bill_customer_sk FROM catalog_sales
    INTERSECT
    SELECT ws_bill_customer_sk FROM web_sales
),
joined_data AS (
    SELECT
        s.cs_bill_customer_sk                     AS cust_sk,
        s.c_first_name,
        s.c_last_name,
        s.c_birth_year,
        s.cs_order_number,
        s.cs_item_sk,
        s.cs_ext_sales_price,
        s.cs_net_profit,
        s.d_year,
        s.i_category,
        s.i_brand,
        i.inv_quantity_on_hand,
        ws.ws_quantity                            AS web_quantity,
        sr.sr_return_amt                          AS store_return_amt,
        wr.wr_return_amt                          AS web_return_amt,
        td.t_hour,
        wp.wp_type,
        wsite.web_country,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY s.cs_bill_customer_sk ORDER BY s.cs_net_profit DESC) AS rn_profit,
        RANK() OVER (PARTITION BY s.i_category ORDER BY s.cs_ext_sales_price DESC)            AS rnk_price,
        CASE WHEN s.c_birth_year < 1960 THEN 'Senior' ELSE 'Adult' END                      AS age_group
    FROM base_sales s
    JOIN common_customers cc ON s.cs_bill_customer_sk = cc.cs_bill_customer_sk
    LEFT JOIN inv_items i ON s.cs_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = s.cs_item_sk AND ws.ws_sold_date_sk = s.cs_sold_date_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = s.cs_item_sk AND sr.sr_returned_date_sk = s.cs_sold_date_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = s.cs_item_sk AND wr.wr_returned_date_sk = s.cs_sold_date_sk
    LEFT JOIN time_dim td ON s.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN customer_demographics cd ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
)
SELECT
    cust_sk,
    c_first_name,
    c_last_name,
    age_group,
    d_year,
    i_category,
    i_brand,
    SUM(cs_ext_sales_price)                         AS total_sales,
    COUNT(DISTINCT cs_order_number)                AS distinct_orders,
    COUNT(DISTINCT cs_item_sk)                     AS distinct_items,
    MAX(rn_profit)                                 AS rank_profit,
    MAX(rnk_price)                                 AS rank_price,
    SUM(inv_quantity_on_hand)                      AS total_inventory_on_hand,
    SUM(store_return_amt)                          AS total_store_returns,
    SUM(web_return_amt)                            AS total_web_returns,
    AVG(web_quantity)                              AS avg_web_quantity,
    MIN(t_hour)                                    AS earliest_hour,
    MAX(wp_type) FILTER (WHERE wp_type IS NOT NULL) AS any_page_type,
    web_country
FROM joined_data
GROUP BY
    cust_sk,
    c_first_name,
    c_last_name,
    age_group,
    d_year,
    i_category,
    i_brand,
    web_country
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
