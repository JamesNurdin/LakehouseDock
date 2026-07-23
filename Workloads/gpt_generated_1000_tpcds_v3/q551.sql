WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cp.cp_department,
        sm.sm_type,
        cd.cd_credit_rating,
        s.s_state,
        ws.web_class,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(cr.cr_net_loss) AS catalog_return_net_loss,
        SUM(wr.wr_net_loss) AS web_return_net_loss
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                            AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cd.cd_credit_rating = 'Good'
      AND s.s_state = 'CA'
      AND ws.web_class = 'A'
    GROUP BY d.d_year, d.d_month_seq, cp.cp_department, sm.sm_type, cd.cd_credit_rating, s.s_state, ws.web_class
)
SELECT
    d_year,
    d_month_seq,
    cp_department,
    sm_type,
    cd_credit_rating,
    s_state,
    web_class,
    catalog_net_paid,
    catalog_net_profit,
    store_net_paid,
    store_net_profit,
    catalog_return_net_loss,
    web_return_net_loss,
    (catalog_net_profit + store_net_profit - catalog_return_net_loss - web_return_net_loss) AS total_profit,
    DENSE_RANK() OVER (PARTITION BY d_year ORDER BY (catalog_net_profit + store_net_profit - catalog_return_net_loss - web_return_net_loss) DESC) AS profit_rank
FROM base
ORDER BY d_year, profit_rank
LIMIT 100
