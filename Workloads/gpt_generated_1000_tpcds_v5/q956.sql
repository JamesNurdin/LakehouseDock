WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        dd.d_year,
        dd.d_date,
        td.t_hour,
        i.i_category,
        i.i_product_name,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        wp.wp_link_count,
        cp.cp_department,
        sr.sr_return_quantity,
        sr.sr_return_amt
    FROM web_sales ws
    JOIN date_dim dd
        ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = dd.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = dd.d_date_sk
        AND sr.sr_item_sk = i.i_item_sk
)
SELECT
    d_year,
    i_category,
    i_product_name,
    cd_gender,
    hd_income_band_sk,
    wp_link_count,
    cp_department,
    ws_quantity,
    ws_net_profit,
    sr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY ws_net_profit DESC) AS profit_rank,
    SUM(ws_ext_sales_price) OVER (
        PARTITION BY i_category
        ORDER BY ws_sold_date_sk
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_7day_sales
FROM base
WHERE
    d_year BETWEEN 2000 AND 2002
    AND i_current_price > 50
    AND wp_link_count >= 5
    AND cd_gender = 'M'
ORDER BY
    d_year DESC,
    profit_rank ASC
LIMIT 100
