WITH
sales_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10) -- sample 10% of rows
),
sales_dim AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_store_sk,
        ss.ss_item_sk,
        t.t_hour,
        i.i_category,
        i.i_brand,
        i.i_item_sk,
        c.c_customer_id,
        cd.cd_gender,
        ca.ca_state,
        s.s_store_name
    FROM sales_sample ss
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
),
returns_dim AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        r.r_reason_desc,
        sr.sr_store_sk,
        sr.sr_item_sk
    FROM store_returns sr
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
),
catalog_ret_dim AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_item_sk,
        cc.cc_name AS call_center_name,
        cp.cp_description AS catalog_page_desc,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        r2.r_reason_desc AS catalog_return_reason
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r2
      ON cr.cr_reason_sk = r2.r_reason_sk
),
sales_without_returns AS (
    SELECT ss_ticket_number
    FROM sales_dim
    EXCEPT
    SELECT sr_ticket_number
    FROM returns_dim
),
sales_with_returns AS (
    SELECT ss_ticket_number
    FROM sales_dim
    INTERSECT
    SELECT sr_ticket_number
    FROM returns_dim
),
union_agg AS (
    SELECT
        'NoReturn' AS return_status,
        sd.s_store_name,
        sd.i_category,
        sd.ss_store_sk,
        sd.i_item_sk,
        SUM(sd.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT sd.ss_ticket_number) AS ticket_cnt,
        CASE WHEN SUM(sd.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
    FROM sales_dim sd
    JOIN sales_without_returns swr
      ON sd.ss_ticket_number = swr.ss_ticket_number
    GROUP BY ROLLUP (sd.s_store_name, sd.i_category, sd.ss_store_sk, sd.i_item_sk)

    UNION

    SELECT
        'HasReturn' AS return_status,
        sd.s_store_name,
        sd.i_category,
        sd.ss_store_sk,
        sd.i_item_sk,
        SUM(sd.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT sd.ss_ticket_number) AS ticket_cnt,
        CASE WHEN SUM(sd.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
    FROM sales_dim sd
    JOIN sales_with_returns swr
      ON sd.ss_ticket_number = swr.ss_ticket_number
    GROUP BY ROLLUP (sd.s_store_name, sd.i_category, sd.ss_store_sk, sd.i_item_sk)
),
final AS (
    SELECT
        ua.return_status,
        ua.s_store_name,
        ua.i_category,
        ua.total_sales,
        ua.ticket_cnt,
        ua.profit_sign,
        lr.total_return_amount
    FROM union_agg ua
    LEFT JOIN LATERAL (
        SELECT SUM(sr.sr_return_amt) AS total_return_amount
        FROM store_returns sr
        WHERE sr.sr_store_sk = ua.ss_store_sk
          AND sr.sr_item_sk = ua.i_item_sk
    ) lr ON true
)
SELECT *
FROM final
ORDER BY total_sales DESC
LIMIT 100
