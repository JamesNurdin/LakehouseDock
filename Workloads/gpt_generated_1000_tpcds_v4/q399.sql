WITH base AS (
    SELECT
        cs.cs_order_number                              AS cs_order_number,
        cs.cs_net_profit                               AS cs_net_profit,
        cs.cs_ext_sales_price                          AS cs_ext_sales_price,
        cs.cs_quantity                                 AS cs_quantity,
        cs.cs_sales_price                              AS cs_sales_price,
        d.d_year                                       AS d_year,
        d.d_current_month                              AS d_current_month,
        t.t_shift                                      AS t_shift,
        c.c_first_name                                 AS c_first_name,
        c.c_last_name                                  AS c_last_name,
        ca.ca_city                                     AS ca_city,
        cd.cd_gender                                   AS cd_gender,
        hd.hd_buy_potential                            AS hd_buy_potential,
        cc.cc_name                                     AS cc_name,
        cp.cp_department                               AS cp_department,
        p.p_promo_name                                 AS p_promo_name,
        cr.cr_return_quantity                          AS cr_return_quantity,
        sr.sr_return_quantity                          AS sr_return_quantity,
        wr.wr_return_quantity                          AS wr_return_quantity,
        r.r_reason_desc                                AS r_reason_desc,
        wp.wp_web_page_id                              AS wp_web_page_id,
        ws.web_name                                    AS web_name
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
)
SELECT
    d_year,
    cs_order_number,
    cs_net_profit,
    cs_ext_sales_price,
    c_first_name,
    c_last_name,
    ca_city,
    cd_gender,
    hd_buy_potential,
    cc_name,
    cp_department,
    p_promo_name,
    COALESCE(cr_return_quantity, 0) AS catalog_return_qty,
    COALESCE(sr_return_quantity, 0) AS store_return_qty,
    COALESCE(wr_return_quantity, 0) AS web_return_qty,
    r_reason_desc,
    wp_web_page_id,
    web_name,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY cs_net_profit DESC) AS profit_rank
FROM base
WHERE
    t_shift = 'first'
    AND hd_buy_potential = '>10000'
    AND d_current_month = 'Y'
    AND cs_quantity > 5
    AND cs_sales_price > 100
    AND cs_net_profit > 0
ORDER BY d_year, profit_rank
LIMIT 100
