WITH base AS (
    SELECT
        d_sold.d_year AS d_year,
        s.s_store_name AS s_store_name,
        i1.i_category AS i_category,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(sr.sr_net_loss) AS total_store_returns,
        SUM(wr.wr_net_loss) AS total_web_returns
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN item i1
        ON cs.cs_item_sk = i1.i_item_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i1.i_item_sk
       AND ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_returns wr
        ON wr.wr_item_sk = i1.i_item_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    GROUP BY d_sold.d_year, s.s_store_name, i1.i_category
)
SELECT
    d_year,
    s_store_name,
    i_category,
    total_sales,
    total_profit,
    total_store_returns,
    total_web_returns,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM base
ORDER BY d_year, profit_rank
