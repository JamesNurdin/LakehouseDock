WITH base AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_category_id,
        t.t_sub_shift,
        c.c_customer_id,
        ss.ss_net_profit,
        cr.cr_return_amount,
        wr.wr_net_loss,
        ws.web_name
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (7, 9)
      AND s.s_state = 'CA'
      AND t.t_sub_shift = 'morning'
)
SELECT
    d_year,
    s_store_id,
    s_store_name,
    i_category,
    SUM(ss_net_profit) AS total_store_profit,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    AVG(cr_return_amount) AS avg_return_amount,
    SUM(wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT web_name) AS web_sites
FROM base
GROUP BY d_year, s_store_id, s_store_name, i_category
HAVING SUM(ss_net_profit) > (
    SELECT AVG(ss2.ss_net_profit)
    FROM tpcds.store_sales ss2
)
ORDER BY total_store_profit DESC
LIMIT 100
