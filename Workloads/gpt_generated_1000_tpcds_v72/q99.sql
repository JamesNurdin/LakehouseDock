WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_list_price,
        cp.cp_department,
        sm.sm_type AS ship_type,
        s.s_store_name,
        s.s_state,
        ca.ca_state AS cust_state,
        cd.cd_gender,
        r.r_reason_desc,
        sr.sr_return_amt,
        wr.wr_return_amt
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND cp.cp_department = 'HOME'
      AND cs.cs_list_price > 50
      AND ss.ss_quantity > 1
),
agg AS (
    SELECT
        b.s_store_name,
        b.cp_department,
        b.ss_customer_sk,
        SUM(b.ss_net_profit) AS total_store_profit,
        SUM(b.cs_net_profit) AS total_catalog_profit,
        SUM(COALESCE(b.sr_return_amt, 0)) AS total_store_returns,
        SUM(COALESCE(b.wr_return_amt, 0)) AS total_web_returns
    FROM base b
    GROUP BY GROUPING SETS (
        (b.s_store_name, b.cp_department, b.ss_customer_sk),
        (b.s_store_name, b.ss_customer_sk),
        (b.cp_department, b.ss_customer_sk)
    )
)
SELECT
    a.s_store_name,
    a.cp_department,
    a.total_store_profit,
    a.total_catalog_profit,
    a.total_store_returns,
    a.total_web_returns,
    (
        SELECT MAX(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = a.ss_customer_sk
    ) AS max_web_return_for_customer,
    RANK() OVER (ORDER BY a.total_store_profit DESC) AS profit_rank
FROM agg a
WHERE a.s_store_name IS NOT NULL
ORDER BY profit_rank
LIMIT 100
