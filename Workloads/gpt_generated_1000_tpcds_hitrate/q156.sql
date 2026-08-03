/*
  Goal: Produce a deep‑join analytical view that combines all 15 selected TPC‑DS tables, aggregates sales and returns per store and product category, enriches the data with customer, promotion, inventory and web activity details, ranks stores by sales, and limits the output to the top 100 rows.
*/
WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    GROUP BY
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number
)
SELECT
    s_store_name,
    i_category,
    d_year,
    call_center_name,
    web_site_name,
    store_sales,
    total_returns,
    inventory_on_hand,
    avg_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY store_sales DESC) AS sales_rank
FROM (
    SELECT
        s.s_store_name AS s_store_name,
        i.i_category AS i_category,
        d_sales.d_year AS d_year,
        cc.cc_name AS call_center_name,
        ws.web_name AS web_site_name,
        SUM(sa.total_sales) AS store_sales,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS inventory_on_hand,
        AVG(p.p_cost) AS avg_promo_cost
    FROM sales_agg sa
    JOIN store s
        ON sa.ss_store_sk = s.s_store_sk
    JOIN item i
        ON sa.ss_item_sk = i.i_item_sk
    JOIN date_dim d_sales
        ON sa.ss_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p
        ON sa.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON sa.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c
        ON sa.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sa.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = sa.ss_ticket_number
    LEFT JOIN item i_ret
        ON sr.sr_item_sk = i_ret.i_item_sk
    LEFT JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return
        ON sr.sr_return_time_sk = t_return.t_time_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sales.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d_sales.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sales.d_date_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'Home'
    )
    GROUP BY
        s.s_store_name,
        i.i_category,
        d_sales.d_year,
        cc.cc_name,
        ws.web_name
) final
ORDER BY store_sales DESC
LIMIT 100
