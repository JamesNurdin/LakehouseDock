WITH joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        d.d_date,
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        i.i_wholesale_cost,
        i.i_manufact,
        i.i_category,
        i.i_brand,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ca.ca_state,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_promo_id,
        p.p_discount_active,
        cp.cp_catalog_page_number,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        wp.wp_url,
        ws.web_name
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    INNER JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
           AND inv.inv_item_sk = i.i_item_sk
    INNER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    INNER JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_wholesale_cost BETWEEN 5.00 AND 10.00
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cp.cp_catalog_page_number IN (3,5)
      AND inv.inv_quantity_on_hand > 20
),

sales_agg AS (
    SELECT
        d_year,
        s_store_id,
        s_store_name,
        i_item_id,
        i_product_name,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_ext_discount_amt) AS total_discount_amt
    FROM joined_data
    GROUP BY d_year, s_store_id, s_store_name, i_item_id, i_product_name
)
SELECT
    d_year,
    s_store_id,
    s_store_name,
    i_item_id,
    i_product_name,
    total_quantity,
    total_sales,
    total_net_profit,
    CASE
        WHEN total_net_profit >= 5000 THEN 'HIGH'
        WHEN total_net_profit >= 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY d_year, profit_rank
LIMIT 100
