WITH cs AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 2
      AND cs.cs_net_paid > 100
),
ss AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_cdemo_sk,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_ticket_number
    FROM store_sales ss
    WHERE ss.ss_sales_price > 50
      AND ss.ss_quantity >= 1
),
wr AS (
    SELECT
        wr.wr_returned_time_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_returned_date_sk
    FROM web_returns wr
    WHERE wr.wr_return_quantity = 1
      AND wr.wr_net_loss > 0
),
joined AS (
    SELECT
        td.t_hour,
        td.t_shift,
        td.t_minute,
        cc.cc_name,
        cd.cd_gender,
        cs.cs_order_number,
        ss.ss_ticket_number,
        wr.wr_returned_date_sk,
        cs.cs_net_paid,
        ss.ss_net_paid,
        wr.wr_net_loss,
        cs.cs_ext_discount_amt,
        ss.ss_sales_price
    FROM cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
       AND ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
       AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE td.t_shift = 'first'
      AND td.t_minute = 15
      AND cc.cc_state = 'CA'
      AND cd.cd_gender = 'M'
)
SELECT
    t_hour,
    t_shift,
    cc_name,
    cd_gender,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    SUM(cs_net_paid) AS total_catalog_net_paid,
    SUM(ss_net_paid) AS total_store_net_paid,
    SUM(wr_net_loss) AS total_return_loss,
    AVG(cs_ext_discount_amt) AS avg_catalog_discount,
    MAX(ss_sales_price) AS max_store_sales_price
FROM joined
GROUP BY t_hour, t_shift, cc_name, cd_gender
ORDER BY total_catalog_net_paid DESC
LIMIT 100
