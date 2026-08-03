WITH store_full AS (
    SELECT
        ss.*,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_reason_sk,
        sr.sr_ticket_number AS sr_ticket_number
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
),
joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_call_center_id,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cr.cr_return_amount,
        ws.ws_sales_price,
        ws.ws_ext_tax,
        we.web_site_id,
        wp.wp_type,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        sf.ss_net_paid,
        sf.sr_return_amt,
        ARRAY[ws.ws_sales_price, sf.ss_net_paid] AS metric_array,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        td.t_hour
    FROM date_dim d
    LEFT JOIN call_center cc               ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs             ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr           ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN store_full sf                ON sf.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws                 ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp                  ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we                  ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN inventory inv                ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN customer_address ca          ON ca.ca_address_sk = COALESCE(sf.ss_addr_sk, ws.ws_bill_addr_sk)
    LEFT JOIN customer_demographics cd     ON cd.cd_demo_sk = COALESCE(sf.ss_cdemo_sk, ws.ws_bill_cdemo_sk)
    LEFT JOIN household_demographics hd    ON hd.hd_demo_sk = COALESCE(sf.ss_hdemo_sk, ws.ws_bill_hdemo_sk)
    LEFT JOIN reason r                     ON r.r_reason_sk = sf.sr_reason_sk
    LEFT JOIN time_dim td                  ON td.t_time_sk = cs.cs_sold_time_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'TX'
      AND we.web_open_date_sk = d.d_date_sk
      AND wp.wp_type = 'home'
      AND ws.ws_ext_tax > 15
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    j.d_year,
    j.d_month_seq,
    j.cc_call_center_id,
    j.profit_flag,
    COUNT(DISTINCT j.cs_order_number)          AS distinct_orders,
    SUM(j.cs_sales_price)                      AS total_catalog_sales,
    SUM(j.cs_net_profit)                       AS total_catalog_profit,
    SUM(j.cr_return_amount)                    AS total_catalog_returns,
    SUM(j.ws_sales_price)                      AS total_web_sales,
    SUM(j.ws_ext_tax)                          AS total_web_tax,
    SUM(j.inv_quantity_on_hand)                AS total_inventory,
    COUNT(DISTINCT j.r_reason_desc)            AS distinct_return_reasons,
    metric_val,
    SUM(metric_val)                            AS metric_sum
FROM joined j
CROSS JOIN UNNEST(j.metric_array) AS t(metric_val)
GROUP BY
    j.d_year,
    j.d_month_seq,
    j.cc_call_center_id,
    j.profit_flag,
    metric_val
ORDER BY
    j.d_year DESC,
    total_catalog_sales DESC
LIMIT 100
