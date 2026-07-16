WITH sales AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_quantity) AS quantity,
        SUM(cs.cs_ext_sales_price) AS revenue
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY cs.cs_bill_customer_sk, d.d_year, d.d_month_seq, i.i_category
    UNION ALL
    SELECT
        ss.ss_customer_sk AS cust_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_quantity) AS quantity,
        SUM(ss.ss_ext_sales_price) AS revenue
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY ss.ss_customer_sk, d.d_year, d.d_month_seq, i.i_category
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_quantity) AS quantity,
        SUM(ws.ws_ext_sales_price) AS revenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY ws.ws_bill_customer_sk, d.d_year, d.d_month_seq, i.i_category
),
returns AS (
    SELECT
        cr.cr_returning_customer_sk AS cust_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS loss,
        SUM(cr.cr_return_quantity) AS return_qty,
        SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY cr.cr_returning_customer_sk, d.d_year, d.d_month_seq, i.i_category
    UNION ALL
    SELECT
        sr.sr_customer_sk AS cust_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(sr.sr_net_loss) AS loss,
        SUM(sr.sr_return_quantity) AS return_qty,
        SUM(sr.sr_return_amt) AS return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY sr.sr_customer_sk, d.d_year, d.d_month_seq, i.i_category
    UNION ALL
    SELECT
        wr.wr_refunded_customer_sk AS cust_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(wr.wr_net_loss) AS loss,
        SUM(wr.wr_return_quantity) AS return_qty,
        SUM(wr.wr_return_amt) AS return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY wr.wr_refunded_customer_sk, d.d_year, d.d_month_seq, i.i_category
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
agg AS (
    SELECT
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.hd_buy_potential,
        cd.ca_state,
        cd.ca_country,
        s.d_year,
        s.d_month_seq,
        s.category,
        SUM(s.profit) AS total_profit,
        SUM(s.quantity) AS total_quantity,
        SUM(s.revenue) AS total_revenue,
        SUM(COALESCE(r.loss, 0)) AS total_loss,
        SUM(COALESCE(r.return_qty, 0)) AS total_return_qty,
        SUM(COALESCE(r.return_amount, 0)) AS total_return_amount
    FROM sales s
    LEFT JOIN returns r
        ON s.cust_sk = r.cust_sk
        AND s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
        AND s.category = r.category
    JOIN customer_details cd
        ON cd.c_customer_sk = s.cust_sk
    GROUP BY
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.hd_buy_potential,
        cd.ca_state,
        cd.ca_country,
        s.d_year,
        s.d_month_seq,
        s.category
    HAVING SUM(s.profit) > 10000
)
SELECT
    a.c_customer_id,
    a.cd_gender,
    a.cd_marital_status,
    a.hd_buy_potential,
    a.ca_state,
    a.ca_country,
    a.d_year,
    a.d_month_seq,
    a.category,
    a.total_profit,
    a.total_quantity,
    a.total_revenue,
    a.total_loss,
    a.total_return_qty,
    a.total_return_amount,
    (a.total_profit - a.total_loss) AS net_profit,
    LAG(a.total_profit - a.total_loss) OVER (PARTITION BY a.c_customer_id ORDER BY a.d_year, a.d_month_seq) AS prev_net_profit,
    ((a.total_profit - a.total_loss) - LAG(a.total_profit - a.total_loss) OVER (PARTITION BY a.c_customer_id ORDER BY a.d_year, a.d_month_seq)) AS net_profit_change,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY (a.total_profit - a.total_loss) DESC) AS profit_rank
FROM agg a
ORDER BY a.d_year, profit_rank
LIMIT 200
