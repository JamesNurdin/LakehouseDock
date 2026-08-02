WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ext_sales_price,
        ss.ss_coupon_amt,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_discount_amt,
        ss.ss_ext_tax,
        ss.ss_ext_list_price,
        ss.ss_ext_wholesale_cost
    FROM store_sales ss
),
joined_all AS (
    SELECT
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_item_sk,
        d.d_year,
        d.d_date,
        d.d_date_sk,
        p.p_discount_active,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cs.cs_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ss_base.ss_ext_sales_price,
        ss_base.ss_coupon_amt,
        ss_base.ss_net_profit,
        ss_base.ss_ticket_number,
        ss_base.ss_quantity,
        ss_base.ss_net_paid_inc_tax
    FROM ss_base
    JOIN date_dim d
        ON ss_base.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss_base.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss_base.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss_base.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss_base.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON ss_base.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss_base.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d.d_year = 2001
        AND s.s_state = 'CA'
        AND i.i_category = 'Sports'
        AND ib.ib_lower_bound >= 130001
        AND ib.ib_upper_bound <= 150000
        AND p.p_discount_active = 'Y'
        AND ss_base.ss_net_paid_inc_tax > 1000
),
agg AS (
    SELECT
        s_store_name,
        s_state,
        i_category,
        d_year,
        i_item_sk,
        d_date,
        d_date_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        AVG(ss_coupon_amt) AS avg_coupon_amount,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        MIN(ss_net_profit) AS min_net_profit,
        MAX(ss_net_profit) AS max_net_profit,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM joined_all
    GROUP BY
        s_store_name,
        s_state,
        i_category,
        d_year,
        i_item_sk,
        d_date,
        d_date_sk
)
SELECT
    s_store_name,
    s_state,
    i_category,
    d_year,
    total_store_sales,
    avg_coupon_amount,
    distinct_tickets,
    min_net_profit,
    max_net_profit,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY d_date) AS sales_seq,
    (SELECT SUM(cs2.cs_ext_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = i_item_sk
       AND cs2.cs_sold_date_sk = d_date_sk) AS total_item_sales_on_date
FROM agg
ORDER BY total_store_sales DESC
LIMIT 100
