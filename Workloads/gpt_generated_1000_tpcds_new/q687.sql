WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cp.cp_catalog_page_number,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        t_sold.t_hour AS sold_hour,
        i.i_category AS category,
        i.i_brand,
        p.p_promo_name,
        sm.sm_type,
        w.w_warehouse_name,
        c.c_customer_id AS customer_id,
        cd.cd_gender,
        ca.ca_state,
        ss.ss_ticket_number,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        s.s_store_name,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        r.r_reason_desc,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid
    FROM
        catalog_sales cs TABLESAMPLE BERNOULLI (10)
        JOIN date_dim d_sold
          ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship
          ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN time_dim t_sold
          ON cs.cs_sold_time_sk = t_sold.t_time_sk
        JOIN item i
          ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p
          ON cs.cs_promo_sk = p.p_promo_sk
        JOIN catalog_page cp
          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
          ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer c
          ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
          ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca
          ON cs.cs_bill_addr_sk = ca.ca_address_sk
        -- store_sales shares the same dimensions
        JOIN store_sales ss
          ON ss.ss_sold_date_sk = d_sold.d_date_sk
         AND ss.ss_item_sk = i.i_item_sk
         AND ss.ss_customer_sk = c.c_customer_sk
         AND ss.ss_cdemo_sk = cd.cd_demo_sk
         AND ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s
          ON ss.ss_store_sk = s.s_store_sk
        JOIN store_returns sr
          ON sr.sr_ticket_number = ss.ss_ticket_number
         AND sr.sr_store_sk = s.s_store_sk
         AND sr.sr_item_sk = i.i_item_sk
         AND sr.sr_customer_sk = c.c_customer_sk
        JOIN reason r
          ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_sales ws
          ON ws.ws_sold_date_sk = d_sold.d_date_sk
         AND ws.ws_item_sk = i.i_item_sk
         AND ws.ws_bill_customer_sk = c.c_customer_sk
         AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
         AND ws.ws_warehouse_sk = w.w_warehouse_sk
),
agg AS (
    SELECT
        customer_id,
        category,
        SUM(cs_net_paid) + SUM(ss_net_paid) + SUM(ws_net_paid) AS total_sales,
        SUM(cs_quantity) + SUM(ss_quantity) + SUM(ws_quantity) AS total_quantity
    FROM base
    GROUP BY GROUPING SETS (
        (customer_id),
        (category),
        ()
    )
)
SELECT
    COALESCE(customer_id, 'ALL') AS customer_id,
    COALESCE(category, 'ALL') AS category,
    total_sales,
    total_quantity,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num
FROM agg
ORDER BY total_sales DESC
OFFSET 10 ROWS
LIMIT 100
