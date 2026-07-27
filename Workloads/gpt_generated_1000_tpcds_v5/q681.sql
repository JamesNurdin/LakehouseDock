WITH agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_catalog_number,
        i.i_item_id,
        t_sold.t_hour AS sale_hour,
        t_return.t_hour AS return_hour,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(cr.cr_net_loss) AS total_return_loss,
        (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss)) AS net_total
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t_sold
        ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN customer_address ca_sold
        ON ss.ss_addr_sk = ca_sold.ca_address_sk
    JOIN catalog_returns cr
        ON i.i_item_sk = cr.cr_item_sk
    JOIN time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    WHERE t_sold.t_am_pm = 'PM'
      AND t_sold.t_shift = 'second'
      AND i.i_formulation LIKE '%steel%'
      AND i.i_current_price BETWEEN 20 AND 200
      AND cp.cp_catalog_number IN (3, 9, 13)
      AND cc.cc_state = 'CA'
      AND ca_sold.ca_country = 'United States'
      AND cr.cr_return_quantity > 0
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_catalog_number,
        i.i_item_id,
        t_sold.t_hour,
        t_return.t_hour
)
SELECT
    agg.cc_call_center_sk,
    agg.cc_name,
    agg.cp_catalog_number,
    agg.i_item_id,
    agg.sale_hour,
    agg.return_hour,
    agg.total_sales_profit,
    agg.total_return_loss,
    agg.net_total,
    RANK() OVER (PARTITION BY agg.cp_catalog_number ORDER BY agg.net_total DESC) AS rank_within_catalog
FROM agg
ORDER BY agg.net_total DESC
LIMIT 100
