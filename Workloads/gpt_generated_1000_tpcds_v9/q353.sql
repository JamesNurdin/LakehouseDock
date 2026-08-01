WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        c_bill.c_customer_id,
        c_bill.c_first_name,
        c_bill.c_last_name,
        c_bill.c_birth_year,
        c_bill.c_preferred_cust_flag,
        c_bill.c_email_address,
        split(c_bill.c_email_address, '@') AS email_parts,
        sm_cs.sm_type,
        w_cs.w_state,
        t_sold.t_hour,
        t_sold.t_minute,
        r.r_reason_desc,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_order_number,
        ws.ws_web_page_sk,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_return_amt
    FROM catalog_sales cs
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer c_bill
      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
      ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN ship_mode sm_cs
      ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w_cs
      ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
     AND ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    WHERE c_bill.c_preferred_cust_flag = 'Y'
      AND c_bill.c_birth_year BETWEEN 1970 AND 1980
      AND sm_cs.sm_type = 'AIR'
      AND w_cs.w_state = 'CA'
      AND t_sold.t_hour = 9
      AND t_sold.t_minute = 30
      AND cs.cs_quantity > (
          SELECT AVG(cs2.cs_quantity)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = 20200101
      )
      AND ws.ws_quantity > 2
      AND r.r_reason_desc LIKE '%damaged%'
      AND EXISTS (
          SELECT 1
          FROM web_page wp2
          WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
            AND wp2.wp_max_ad_count <= 1
      )
),
agg AS (
    SELECT
        base.c_customer_id,
        base.c_first_name,
        base.c_last_name,
        base.sm_type AS ship_mode_type,
        base.t_hour,
        email_part,
        COUNT(DISTINCT base.cs_order_number) AS order_cnt,
        SUM(base.cs_net_paid) AS total_catalog_sales,
        SUM(base.ws_net_paid) AS total_web_sales,
        SUM(base.cr_net_loss) AS total_catalog_returns,
        SUM(base.wr_net_loss) AS total_web_returns,
        SUM(CASE WHEN base.r_reason_desc LIKE '%damaged%' THEN base.cs_net_paid ELSE 0 END) AS damaged_sales_total,
        AVG(base.cs_quantity) AS avg_quantity
    FROM base
    CROSS JOIN UNNEST(base.email_parts) AS t(email_part)
    GROUP BY
        base.c_customer_id,
        base.c_first_name,
        base.c_last_name,
        base.sm_type,
        base.t_hour,
        email_part
)
SELECT
    agg.c_customer_id,
    agg.c_first_name,
    agg.c_last_name,
    agg.ship_mode_type,
    agg.t_hour,
    agg.email_part,
    agg.order_cnt,
    agg.total_catalog_sales,
    agg.total_web_sales,
    agg.total_catalog_returns,
    agg.total_web_returns,
    agg.damaged_sales_total,
    agg.avg_quantity,
    ROW_NUMBER() OVER (ORDER BY agg.total_catalog_sales DESC) AS sales_rank
FROM agg
ORDER BY sales_rank
LIMIT 100
