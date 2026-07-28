WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_item_id,
        i.i_product_name,
        ss.ss_net_paid,
        cs.cs_net_paid,
        ws.ws_net_paid,
        sr.sr_net_loss
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON i.i_item_sk = ss.ss_item_sk
    WHERE d.d_year = 2001
      AND i.i_manager_id IN (34, 21)
      AND ss.ss_quantity > 1
      AND cs.cs_quantity > 0
      AND ws.ws_quantity > 0
),
agg AS (
    SELECT
        i_item_id,
        i_product_name,
        d_year,
        SUM(ss_net_paid) AS sum_ss,
        SUM(cs_net_paid) AS sum_cs,
        SUM(ws_net_paid) AS sum_ws,
        COALESCE(SUM(sr_net_loss), 0) AS sum_sr_loss
    FROM joined_data
    GROUP BY i_item_id, i_product_name, d_year
)
SELECT
    i_item_id,
    i_product_name,
    d_year,
    (sum_ss + sum_cs + sum_ws - sum_sr_loss) AS total_net_amount,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (sum_ss + sum_cs + sum_ws - sum_sr_loss) DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 10
