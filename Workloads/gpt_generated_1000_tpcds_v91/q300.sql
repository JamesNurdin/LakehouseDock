WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    WHERE inv_warehouse_sk IN (1, 3)
    GROUP BY inv_item_sk, inv_date_sk
),
unioned AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_item_id AS item_id,
        SUM(ss.ss_ext_sales_price) AS sales_ext_price,
        SUM(ss.ss_net_profit) AS sales_net_profit,
        SUM(COALESCE(sr.sr_refunded_cash, 0)) AS returns_refunded_cash,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS returns_net_loss
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory_agg invagg ON invagg.inv_item_sk = i.i_item_sk
        AND invagg.inv_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    WHERE d_sales.d_year = 2001
      AND d_sales.d_month_seq BETWEEN 1 AND 3
      AND t_sales.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'Brand#45'
      AND cd.cd_gender = 'M'
      AND ca.ca_state = 'TX'
      AND s.s_state = 'CA'
      AND invagg.total_quantity_on_hand > 500
      AND (r.r_reason_desc LIKE '%damaged%' OR r.r_reason_desc IS NULL)
    GROUP BY s.s_store_id, i.i_item_id
    UNION
    SELECT
        s.s_store_id AS store_id,
        i.i_item_id AS item_id,
        SUM(ss.ss_ext_sales_price) AS sales_ext_price,
        SUM(ss.ss_net_profit) AS sales_net_profit,
        SUM(COALESCE(sr.sr_refunded_cash, 0)) AS returns_refunded_cash,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS returns_net_loss
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory_agg invagg ON invagg.inv_item_sk = i.i_item_sk
        AND invagg.inv_date_sk = d_sales.d_date_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    WHERE d_sales.d_year = 2000
      AND d_sales.d_month_seq BETWEEN 4 AND 6
      AND t_sales.t_hour BETWEEN 10 AND 15
      AND i.i_brand = 'Brand#45'
      AND cd.cd_gender = 'F'
      AND ca.ca_state = 'NY'
      AND s.s_state = 'NY'
      AND invagg.total_quantity_on_hand > 400
      AND (r.r_reason_desc LIKE '%defective%' OR r.r_reason_desc IS NULL)
    GROUP BY s.s_store_id, i.i_item_id
)
SELECT
    store_id,
    item_id,
    SUM(sales_ext_price) AS total_sales_ext_price,
    SUM(sales_net_profit) AS total_sales_net_profit,
    SUM(returns_refunded_cash) AS total_returns_refunded_cash,
    SUM(returns_net_loss) AS total_returns_net_loss,
    CASE
        WHEN SUM(sales_net_profit) - SUM(returns_net_loss) > 15000 THEN 'High'
        WHEN SUM(sales_net_profit) - SUM(returns_net_loss) BETWEEN 8000 AND 15000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM unioned
GROUP BY store_id, item_id
ORDER BY total_sales_net_profit DESC
LIMIT 100
