WITH joined_data AS (
    SELECT
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        s.s_manager,
        d1.d_year,
        d1.d_month_seq
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d1.d_date_sk
                           AND sr.sr_return_time_sk = t1.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
                       AND ws.ws_sold_time_sk = t1.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d1.d_date_sk
                         AND wr.wr_returned_time_sk = t1.t_time_sk
                         AND wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
                         AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d1.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND s.s_manager = 'Scott Smith'
      AND cd.cd_education_status = 'Advanced Degree'
      AND c.c_birth_country = 'United States'
      AND wp.wp_type = 'product'
      AND wsite.web_class = 'news'
      AND cs.cs_quantity > 5
),
agg AS (
    SELECT
        s_manager,
        d_year,
        d_month_seq,
        SUM(cs_net_profit) AS sum_sales_profit,
        SUM(ws_net_profit) AS sum_web_profit,
        SUM(sr_net_loss) AS sum_return_loss,
        SUM(wr_net_loss) AS sum_web_return_loss
    FROM joined_data
    GROUP BY s_manager, d_year, d_month_seq
)
SELECT
    s_manager,
    d_year,
    d_month_seq,
    (sum_sales_profit + sum_web_profit - sum_return_loss - sum_web_return_loss) AS total_profit,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY (sum_sales_profit + sum_web_profit - sum_return_loss - sum_web_return_loss) DESC) AS profit_rank,
    ROW_NUMBER() OVER (ORDER BY (sum_sales_profit + sum_web_profit - sum_return_loss - sum_web_return_loss) DESC) AS overall_rank
FROM agg
ORDER BY d_year, d_month_seq, profit_rank
