WITH
store_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_category,
        t.t_hour,
        c.c_customer_id,
        cd.cd_gender,
        r.r_reason_desc,
        SUM(ss.ss_net_paid) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_txn_cnt,
        COALESCE(SUM(sr.sr_return_amt), 0) AS store_return_amt,
        COALESCE(SUM(sr.sr_net_loss), 0) AS store_net_loss
    FROM time_dim t
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON i.i_item_sk = ss.ss_item_sk
    JOIN customer c
        ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = ss.ss_cdemo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        t.t_hour BETWEEN 9 AND 17
        AND c.c_birth_year > 1970
        AND i.i_current_price > 100
        AND (r.r_reason_desc LIKE '%exchange%' OR r.r_reason_desc IS NULL)
        AND ss.ss_quantity > 0
    GROUP BY
        i.i_item_id,
        i.i_brand,
        i.i_category,
        t.t_hour,
        c.c_customer_id,
        cd.cd_gender,
        r.r_reason_desc
),
web_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_category,
        t.t_hour,
        c.c_customer_id,
        cd.cd_gender,
        r.r_reason_desc,
        SUM(ws.ws_net_paid) AS web_sales_amount,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_txn_cnt,
        COALESCE(SUM(wr.wr_return_amt), 0) AS web_return_amt,
        COALESCE(SUM(wr.wr_net_loss), 0) AS web_net_loss
    FROM time_dim t
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
        ON i.i_item_sk = ws.ws_item_sk
    JOIN customer c
        ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        t.t_hour BETWEEN 9 AND 17
        AND c.c_birth_year > 1970
        AND i.i_current_price > 100
        AND (r.r_reason_desc LIKE '%exchange%' OR r.r_reason_desc IS NULL)
        AND ws.ws_quantity > 0
    GROUP BY
        i.i_item_id,
        i.i_brand,
        i.i_category,
        t.t_hour,
        c.c_customer_id,
        cd.cd_gender,
        r.r_reason_desc
),
combined_sales AS (
    SELECT
        i_item_id,
        i_brand,
        i_category,
        t_hour,
        c_customer_id,
        cd_gender,
        r_reason_desc,
        store_sales_amount AS sales_amount,
        store_net_profit AS net_profit,
        store_txn_cnt AS txn_cnt,
        store_return_amt AS return_amt,
        store_net_loss AS net_loss
    FROM store_sales_agg
    UNION ALL
    SELECT
        i_item_id,
        i_brand,
        i_category,
        t_hour,
        c_customer_id,
        cd_gender,
        r_reason_desc,
        web_sales_amount,
        web_net_profit,
        web_txn_cnt,
        web_return_amt,
        web_net_loss
    FROM web_sales_agg
),
grouped_sales AS (
    SELECT
        i_item_id,
        i_brand,
        i_category,
        t_hour,
        SUM(sales_amount) AS total_sales,
        SUM(net_profit) AS total_profit,
        SUM(return_amt) AS total_returns,
        SUM(net_loss) AS total_net_loss,
        COUNT(*) AS row_cnt
    FROM combined_sales
    GROUP BY GROUPING SETS (
        (i_item_id, i_brand, i_category, t_hour),
        (i_brand, i_category, t_hour),
        (i_category, t_hour),
        (t_hour),
        ()
    )
)
SELECT
    i_item_id,
    i_brand,
    i_category,
    t_hour,
    total_sales,
    total_profit,
    total_returns,
    total_net_loss,
    row_cnt,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM grouped_sales
ORDER BY total_sales DESC
LIMIT 100
