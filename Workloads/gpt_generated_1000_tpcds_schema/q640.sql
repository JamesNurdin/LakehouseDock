WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_ext_wholesale_cost,
        c.c_customer_id,
        cd.cd_gender,
        i.i_item_id,
        i.i_color,
        w.w_warehouse_id,
        w.w_country,
        t.t_am_pm,
        t.t_sub_shift,
        r.r_reason_desc,
        sr.sr_fee,
        wp.wp_url,
        cs.cs_sold_time_sk,
        ss.ss_ticket_number
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_sold_time_sk = t.t_time_sk
     AND ss.ss_customer_sk = c.c_customer_sk
     AND ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_return_time_sk = t.t_time_sk
     AND sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_cdemo_sk = cd.cd_demo_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_wholesale_cost > 2000
      AND cs.cs_net_paid_inc_ship >= 1000
      AND w.w_country = 'United States'
      AND t.t_am_pm = 'PM'
      AND t.t_sub_shift = 'evening'
      AND sr.sr_fee > 20
      AND EXISTS (
            SELECT 1 FROM reason r2
            WHERE r2.r_reason_sk = sr.sr_reason_sk
              AND r2.r_reason_desc = 'Damaged'
          )
      AND wp.wp_rec_start_date >= DATE '2000-01-01'
),
ranked_top AS (
    SELECT
        cs_order_number,
        cs_net_paid_inc_ship,
        w_warehouse_id,
        RANK() OVER (PARTITION BY w_warehouse_id ORDER BY cs_net_paid_inc_ship DESC) AS rnk_desc
    FROM base
),
ranked_low AS (
    SELECT
        cs_order_number,
        cs_net_paid_inc_ship,
        w_warehouse_id,
        RANK() OVER (PARTITION BY w_warehouse_id ORDER BY cs_net_paid_inc_ship ASC) AS rnk_asc
    FROM base
    WHERE i_color = 'Red'
),
exclude_set AS (
    SELECT
        cs_order_number,
        cs_net_paid_inc_ship,
        w_warehouse_id,
        RANK() OVER (PARTITION BY w_warehouse_id ORDER BY cs_net_paid_inc_ship DESC) AS rnk_excl
    FROM base
    WHERE cs_ext_wholesale_cost > 5000
)
SELECT cs_order_number,
       cs_net_paid_inc_ship,
       w_warehouse_id,
       rnk_desc AS rank_in_warehouse
FROM ranked_top
WHERE rnk_desc <= 5

UNION DISTINCT

SELECT cs_order_number,
       cs_net_paid_inc_ship,
       w_warehouse_id,
       rnk_asc AS rank_in_warehouse
FROM ranked_low
WHERE rnk_asc <= 3

EXCEPT

SELECT cs_order_number,
       cs_net_paid_inc_ship,
       w_warehouse_id,
       rnk_excl AS rank_in_warehouse
FROM exclude_set
WHERE rnk_excl <= 2

LIMIT 100
